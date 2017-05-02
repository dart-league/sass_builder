import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart';
import 'package:sass/sass.dart';

class SassBuilder implements Builder {
  Set<AssetId> mainInputs = new Set();

  Logger _log = new Logger('SassBuilder');

  @override
  Future build(BuildStep buildStep) async {
    _log.info('processing changed file: ${buildStep.inputId}');
    _log.info('using mainInputs: $mainInputs');
    if (mainInputs.isNotEmpty) {
      for (var mainInput in mainInputs) {
        var css = await render(mainInput.path, packageResolver: await PackageResolver.current.asSync);
//        buildStep.writeAsString(_changeExtension(mainInput), css);
        var file = new File(_changeExtension(mainInput).path);
        await file.create(recursive: true);
        await file.writeAsString(css);
      }
      mainInputs = new Set();
    }
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) {
    if (!basename(inputId.path).startsWith('_')) mainInputs.add(inputId);

    return [_changeExtension(inputId)];
  }
}

AssetId _changeExtension(AssetId inputId) => inputId.changeExtension('.css');