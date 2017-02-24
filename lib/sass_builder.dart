import 'dart:async';
import 'package:build/build.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart';
import 'package:sass/sass.dart';

class SassBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;
    var inputUri = Uri.parse(inputId.path);
    if (inputUri.scheme == 'package' || basename(inputId.path).startsWith('_')) return null;

    var css = await render(inputId.path, packageResolver: await PackageResolver.current.asSync);
    buildStep.writeAsString(_changeExtension(inputId), css);
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) => [_changeExtension(inputId)];
}

AssetId _changeExtension(AssetId inputId) => inputId.changeExtension('.css');