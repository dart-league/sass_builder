import 'dart:async';
import 'dart:collection';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart';
import 'package:sass/sass.dart';
import 'package:scratch_space/scratch_space.dart';

final _packageNameRegExp = new RegExp(r'''package:([^\/]*)\/''');
final _packagePathRegExp = new RegExp(r'''package:[^\/]*\/(.*)''');
final _scssImportBlockRegExp =
    new RegExp(r'''@import ([^;]*);''', multiLine: true);
final _sassImportBlockRegExp = new RegExp(r'''@import (.*)$''');
final _scssfileNameRegExp = new RegExp(r'''(?:\'|\")([^\'\"]*)(?:\'|\")''');
final _sassfileNameRegExp = new RegExp(r'''['"]?([^ ,'"]+)['"]?''');
final _scssCommentRegExp =
    new RegExp(r'''//.*?\n|/\*.*?\*/''', multiLine: true);

Builder sassBuilder(_) => new SassBuilder();

/// A `Builder` to compile .css files from .scss source using dart-sass.
///
/// NOTE: Because Sass requires reading from the disk this `Builder` copies all
/// `Assets` to a temporary directory with a structure similar to that defined
/// in `.packages`. Sass will read from the temporary directory when compiling.
class SassBuilder implements Builder {
  static final _scratchSpaceResource = new Resource<ScratchSpace>(
      () => new ScratchSpace(),
      dispose: (temp) => temp.delete());

  final _log = new Logger('sass_builder');
  final String _outputExtension;

  SassBuilder({String outputExtension: '.css'})
      : this._outputExtension = outputExtension;

  @override
  Future build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;

    if (basename(inputId.path).startsWith('_')) {
      // Do not produce any output for .scss partials.
      _log.fine('skipping partial file: ${inputId}');
      return;
    }

    // Read and copy this asset and all imported assets to the temp directory.
    _log.fine('processing file: ${inputId}');
    var tempDir = await buildStep.fetchResource(_scratchSpaceResource);
    await _readAndCopyImports(inputId, buildStep, tempDir);

    // Compile the css.
    var tempAssetPath = tempDir.fileFor(inputId).path;
    _log.fine('compiling file: ${tempAssetPath}');
    var cssOutput = compile(tempAssetPath,
        packageResolver: new SyncPackageResolver.root(tempDir.packagesDir.uri));

    // Write the builder output
    var outputId = inputId.changeExtension(_outputExtension);
    buildStep.writeAsString(outputId, '${cssOutput}\n');
    _log.fine('wrote css file: ${outputId.path}');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.scss': [_outputExtension],
        '.sass': [_outputExtension],
      };

  // Reads `id` and all transitive imports while copying them to `tempDir`.
  //
  // Uses `buildStep to read the assets and the `ScratchSpace` API to write
  // `tempDir`.
  Future _readAndCopyImports(
      AssetId id, BuildStep buildStep, ScratchSpace tempDir) async {
    var copiedAssets = new Set<AssetId>();
    var assetsToCopy = new Queue<AssetId>();
    assetsToCopy.add(id);

    while (assetsToCopy.isNotEmpty) {
      id = assetsToCopy.removeFirst();

      if (!copiedAssets.contains(id)) {
        var contents = await buildStep.readAsString(id);
        _log.fine('read file: ${id}');
        await tempDir.ensureAssets([id], buildStep);
        copiedAssets.add(id);

        var imports = await _importedAssets(id, contents, buildStep);
        assetsToCopy.addAll(imports);
        var importLog = imports.fold('', (acc, import) => '$acc\n  ${import}');
        _log.fine('found imports:$importLog');
      }
    }
  }

  // Returns the `AssetId`s of all the scss imports in `contents`.
  Future<Iterable<AssetId>> _importedAssets(
      AssetId id, String contents, BuildStep buildStep) async {
    var importedAssets = new Set<AssetId>();

    var importBlocks = id.extension == '.scss'
        ? _scssImportBlockRegExp
            .allMatches(contents.replaceAll(_scssCommentRegExp, ''))
        : _sassImportBlockRegExp.allMatches(contents);

    for (var importBlock in importBlocks) {
      var imports = id.extension == '.scss'
          ? _scssfileNameRegExp.allMatches(importBlock.group(1))
          : _sassfileNameRegExp.allMatches(importBlock.group(1));
      for (var import in imports) {
        var importId = await _findImport(
            _importPackage(import.group(1), id.package),
            _importPath(import.group(1), id.path),
            buildStep);
        if (importId == null) {
          // Only copy imports that are found. If there is a problem with a
          // missing file, let sass compilation fail and report it.
          _log.severe('could not read file: ${importId}');
          continue;
        }

        importedAssets.add(importId);
      }
    }

    return importedAssets;
  }

  // Returns the package name parsed from the given `import` or defaults to
  // `currentPackage`.
  String _importPackage(String import, String currentPackage) =>
      import.startsWith('package:')
          ? _packageNameRegExp.firstMatch(import).group(1)
          : currentPackage;

  // Returns the path parsed from the given `import` or defaults to
  // locating the file in the `currentPath`.
  String _importPath(String import, String currentPath) =>
      import.startsWith('package:')
          ? join('lib', _packagePathRegExp.firstMatch(import).group(1))
          : join(dirname(currentPath), import);

  // Locates the asset for `path` in `package` or returns null if unreadable.
  //
  // Probes for different versions of the path in case the file is a parial
  // (leading underscore can be ommited) or if the extension is ommited per the
  // SASS `@import` syntax. Tests for file readability via `buildStep`.
  Future<AssetId> _findImport(
      String package, String path, BuildStep buildStep) async {
    var importId = new AssetId(package, path);

    if (await buildStep.canRead(importId)) {
      // File was found as written in the import.
      return importId;
    }

    // Try as a patial.
    var partialFile = new AssetId(package, _asPartial(path));
    if (await buildStep.canRead(partialFile)) {
      return partialFile;
    }

    // Try adding the .scss extension.
    var scssPath = '$path.scss';
    var scssFile = new AssetId(package, scssPath);
    if (await buildStep.canRead(scssFile)) {
      return scssFile;
    }

    partialFile = new AssetId(package, _asPartial(scssPath));
    if (await buildStep.canRead(partialFile)) {
      return partialFile;
    }

    // Try adding the .sass extension
    var sassPath = '$path.sass';
    var sassFile = new AssetId(package, sassPath);
    if (await buildStep.canRead(sassFile)) {
      return sassFile;
    }

    partialFile = new AssetId(package, _asPartial(sassPath));
    if (await buildStep.canRead(partialFile)) {
      return partialFile;
    }

    // No version of the filename was found.
    return null;
  }

  String _asPartial(String path) => join(dirname(path), '_${basename(path)}');
}
