import 'package:barback/barback.dart';
import 'package:build_barback/build_barback.dart';
import 'sass_builder.dart';

/// A pub transformer simply wrapping the [SassBuilder].
class SassBuilderTransform extends BuilderTransformer {
  static final _outputExtensionKey = 'outputExtension';
  SassBuilderTransform() : super(new SassBuilder());

  SassBuilderTransform.customExtension(String outputExtension)
      : super(new SassBuilder(outputExtension: outputExtension));

  factory SassBuilderTransform.asPlugin(BarbackSettings settings) {
    if (settings.configuration.containsKey(_outputExtensionKey)) {
      return new SassBuilderTransform.customExtension(
          settings.configuration[_outputExtensionKey]);
    }
    return new SassBuilderTransform();
  }
}
