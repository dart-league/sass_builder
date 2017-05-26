import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart';
import 'package:sass/sass.dart';

class SassBuilder implements Builder {

  Logger _log = new Logger('SassBuilder');

  Set<AssetId> _mainInputs;

  Set<AssetId> get mainInputs {
    if (_mainInputs == null) {
      var sassBuildFile = new File(join(Directory.current.path, '.dart_tool', 'sass_build_main_inputs.json'));
      if (sassBuildFile.existsSync()) {
        var mainInputsJson = sassBuildFile.readAsStringSync();
        mainInputsJson = mainInputsJson.isEmpty ? '[]' : mainInputsJson;
        List mainInputsList = JSON.decode(mainInputsJson);
        mainInputsList = mainInputsList == null || mainInputsList.isEmpty ? [] : mainInputsList;
        _mainInputs = new Set();
        for (var mainInputStr in mainInputsList) {
          _mainInputs.add(new AssetId.parse(mainInputStr));
        }
      } else {
        _mainInputs = new Set();
      }
    }
    return _mainInputs;
  }

  _saveMainInputs() {
    var sassBuildFile = new File(join(Directory.current.path, '.dart_tool', 'sass_build_main_inputs.json'));
    if (!sassBuildFile.existsSync()) sassBuildFile.createSync(recursive: true);

    _log.info('writing mainInputs: $_mainInputs');
    sassBuildFile.writeAsStringSync(JSON.encode(_mainInputs.map((mi) => mi.toString()).toList()));
  }

  @override
  Future build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;
    _log.info('processing changed file: ${inputId}');

    if (!basename(inputId.path).startsWith('_')) {
      if (!mainInputs.contains(inputId)) {
        mainInputs.add(inputId);
        _saveMainInputs();
      }
    }
    _log.info('using mainInputs: $mainInputs');

    if (mainInputs.isNotEmpty) {
      for (var mainInput in mainInputs) {
        _log.info('parsing: ${mainInput}');
        var css = await render(mainInput.path, packageResolver: await PackageResolver.current.asSync);
//        buildStep.writeAsString(_changeExtension(mainInput), css);
        var file = new File(mainInput.changeExtension('.css').path);
        file.createSync(recursive: true);
        file.writeAsString(css);
      }
    }
  }

  @override
  Map<String,List<String>> get buildExtensions =>
    {

    '': const ['.xxxxx']  // since we are writing files without buildStep, we need to have a fake extension
  };
}
