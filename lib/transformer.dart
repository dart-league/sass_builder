import 'package:build_barback/build_barback.dart';
import 'sass_builder.dart';

/// A pub transformer simply wrapping the [SassBuilder].
class SassBuilderTransform extends BuilderTransformer {
  SassBuilderTransform.asPlugin(settings)
      : super(new SassBuilder(settings: settings));
}
