import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:sass_builder/sass_builder.dart';
import 'package:test/test.dart';

void main() {
  // These tests only verify which assets are read and written by the
  // SassBuilder. This is because the inputs are being parsed to find what files
  // they import.
  //
  // These tests do not verify any output as that is determined by the sass
  // implementation.
  group('File import parsing tests', () {
    SassBuilder builder;
    InMemoryAssetWriter writer;
    InMemoryAssetReader reader;

    setUp(() {
      builder = new SassBuilder();
      reader = new InMemoryAssetReader();
      writer = new InMemoryAssetWriter();
    });

    test('no imports, one read and one write', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var inputs = {
        primary: '/* no imports */',
      };

      reader.cacheStringAsset(primary, inputs[primary]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, equals([primary]));
    });

    test('one relative partial import', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import = makeAssetId('a|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import '_more_styles.scss';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, unorderedEquals([primary, import]));
    });

    test('one relative partial import simplified name', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import = makeAssetId('a|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import 'more_styles';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));

      expect(reader.assetsRead, contains(primary));
      expect(reader.assetsRead, contains(import));
    });

    test('one relative import', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import = makeAssetId('a|lib/foo/more_styles.scss');
      var inputs = {
        primary: '''@import 'foo/more_styles';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import.changeExtension('.css')
          ]));
      expect(reader.assetsRead, unorderedEquals([primary, import]));
    });

    test('one package import', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import = makeAssetId('b|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import 'package:b/more_styles';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));

      expect(reader.assetsRead, contains(primary));
      expect(reader.assetsRead, contains(import));
    });

    test('multiple imports in one block', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import1 = makeAssetId('b|lib/more_styles.scss');
      var import2 = makeAssetId('a|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import 'package:b/more_styles','''
            '''        'more_styles';''',
        import1: '''/* no imports */''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import1.changeExtension('.css')
          ]));

      expect(reader.assetsRead, contains(primary));
      expect(reader.assetsRead, contains(import1));
      expect(reader.assetsRead, contains(import2));
    });

    test('multiple imports in multiple blocks', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import1 = makeAssetId('b|lib/more_styles.scss');
      var import2 = makeAssetId('a|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import 'package:b/more_styles';'''
            '''@import 'more_styles';''',
        import1: '''/* no imports */''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import1.changeExtension('.css')
          ]));

      expect(reader.assetsRead, contains(primary));
      expect(reader.assetsRead, contains(import1));
      expect(reader.assetsRead, contains(import2));
    });

    test('transitive imports', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import1 = makeAssetId('b|lib/styles.scss');
      var import2 = makeAssetId('b|lib/_more_styles.scss');
      var inputs = {
        primary: '''@import 'package:b/more_styles';''',
        import1: '''@import 'more_styles';''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import1.changeExtension('.css')
          ]));

      expect(reader.assetsRead, contains(primary));
      expect(reader.assetsRead, contains(import1));
      expect(reader.assetsRead, contains(import2));
    });
  });
}
