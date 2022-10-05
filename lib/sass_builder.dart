import 'dart:async';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:sass/sass.dart' as sass;

import 'src/build_importer.dart';

final outputStyleKey = 'outputStyle';

Builder sassBuilder(BuilderOptions options) =>
    SassBuilder(outputStyle: options.config[outputStyleKey]);

PostProcessBuilder sassSourceCleanup(BuilderOptions options) =>
    FileDeletingBuilder(['.scss', '.sass'],
        isEnabled: (options.config['enabled'] as bool?) ?? false);

/// A `Builder` to compile `.css` files from `.scss` or `.sass` source using
/// the dart implementation of Sass.
class SassBuilder implements Builder {
  static final _defaultOutputStyle = sass.OutputStyle.expanded;
  static final _outputStylesByName = sass.OutputStyle.values.asNameMap();

  final String _outputExtension;
  final String _outputStyle;

  SassBuilder({String outputExtension = '.css', String? outputStyle})
      : _outputExtension = outputExtension,
        _outputStyle = outputStyle ?? _defaultOutputStyle.toString();

  @override
  Future build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    if (p.basename(inputId.path).startsWith('_')) {
      // Do not produce any output for .scss partials.
      log.fine('skipping partial file: $inputId');
      return;
    }

    // Compile the css.
    log.fine('compiling file: ${inputId.uri.toString()}');
    final compileResult = await sass.compileStringToResultAsync(
      await buildStep.readAsString(inputId),
      syntax: sass.Syntax.forPath(inputId.path),
      importers: [BuildImporter(buildStep)],
      style: _getValidOutputStyle(),
      url: inputId.uri,
    );
    final cssOutput = compileResult.css;

    // Write the builder output.
    final outputId = inputId.changeExtension(_outputExtension);
    await buildStep.writeAsString(outputId, '$cssOutput\n');
    log.fine('wrote css file: ${outputId.path}');
  }

  /// Returns a valid `OutputStyle` value to the `style` argument of
  /// [sass.compileStringToResult] during a [build].
  ///
  /// * If [_outputStyle] is not `OutputStyle.compressed` or
  /// `OutputStyle.expanded`, a warning will be logged informing the user
  /// that the [_defaultOutputStyle] will be used.
  sass.OutputStyle _getValidOutputStyle() {
    final style = _outputStylesByName[_outputStyle];

    if (style != null) {
      return style;
    } else {
      log.warning('Unknown outputStyle provided: "$_outputStyle". '
          'Supported values are: "expanded" and "compressed". The default '
          'value of "${_defaultOutputStyle.toString()}" will be used.');
      return _defaultOutputStyle;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.scss': [_outputExtension],
        '.sass': [_outputExtension],
      };
}
