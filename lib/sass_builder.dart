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
final _importBlockRegExp = new RegExp(r'''@import ([^;]*);''', multiLine: true);
final _fileNameRegExp = new RegExp(r'''(?:\'|\")([^\'\"]*)(?:\'|\")''');
final _sassCommentRegExp =
    new RegExp(r'''//.*?\n|/\*.*?\*/''', multiLine: true);

/// A `Builder` to compile .css files from .scss source using dart-sass.
///
/// NOTE: Because Sass requires reading from the disk this `Builder` copies all
/// `Assets` to a temporary directory with a structure similar to that defined
/// in `.packages`. Sass will read from the temporary directory when compiling.
class SassBuilder implements Builder {
  Logger _log = new Logger('SassBuilder');
  String _outputExtension;
  static final _scratchSpaceResource = new Resource<ScratchSpace>(
          () => new ScratchSpace(),
      dispose: (temp) => temp.delete());

  SassBuilder({String outputExtension: '.css'}) {
    _outputExtension =  outputExtension;
  }

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

    for (var importBlock in _importBlockRegExp
        .allMatches(contents.replaceAll(_sassCommentRegExp, ''))) {
      var imports = _fileNameRegExp.allMatches(importBlock.group(1));
      for (var import in imports) {
        var importId = new AssetId(_importPackage(import.group(1), id.package),
            _importPath(import.group(1), id.path));

        if (!await buildStep.canRead(importId)) {
          // Try same asset path except filename starting with an underscore.
          _log.fine('could not read file: ${importId}');
          importId = new AssetId(importId.package,
              join(dirname(importId.path), '_${basename(importId.path)}'));

          if (!await buildStep.canRead(importId)) {
            // Only copy imports that are found. If there is a problem with a
            // missing file, let sass compilation fail and report it.
            _log.severe('could not read file: ${importId}');
            continue;
          }
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
  String _importPath(String import, String currentPath) {
    var path = import.startsWith('package:')
        ? join('lib', _packagePathRegExp.firstMatch(import).group(1))
        : join(dirname(currentPath), import);

    return path.endsWith('.scss') ? path : '$path.scss';
  }
}
