import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'sass_builder.dart';

/// A pub transformer simply wrapping the [SassBuilder].
class SassBuilderTransform extends BuilderTransformer {
  static final _outputExtensionKey = 'outputExtension';
  SassBuilderTransform(SassBuilder builder) : super(builder);

  factory SassBuilderTransform.asPlugin(BarbackSettings settings) {
    SassBuilder builder;
    var outputStyle = settings.configuration[outputStyleKey] as String;

    if (settings.configuration.containsKey(_outputExtensionKey)) {
      builder = new SassBuilder(
        outputExtension: settings.configuration[_outputExtensionKey] as String,
        outputStyle: outputStyle,
      );
    } else {
      builder = new SassBuilder(outputStyle: outputStyle);
    }

    return new SassBuilderTransform(builder);
  }
}
