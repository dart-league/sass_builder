import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:sass_builder/sass_builder.dart';
import 'package:test/test.dart';

void main() {
  /// These tests only verify which assets are read and written by the
  /// [SassBuilder]. This is to test the behaivor of the AsyncImporter used to
  /// handle Dart package imports and perform all file IO through the
  /// build_step.
  ///
  /// In some cases additional dependencies are created on files that do not
  /// exists because Sass allows the user to ommit the file extensions `.scss`
  /// or `.sass`, the partial prefix `_` or the file name altogether. These
  /// tests avoid testing for those dependencies that are created when probing
  /// for imports.
  ///
  /// These tests do not verify any output as that is determined by the Sass
  /// implementation.
  group('build IO tests', () {
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
      expect(reader.assetsRead, containsAll([primary, import]));
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
      expect(reader.assetsRead, containsAll([primary, import]));
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
      expect(reader.assetsRead, containsAll([primary, import]));
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
      expect(reader.assetsRead, containsAll([primary, import]));
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
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
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
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
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

      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });

    test('consults include path', () async {
      var primary = makeAssetId('a|lib/syles.scss');
      var import = makeAssetId('a|search_path/module/styles.scss');
      var inputs = {
        primary: '''@import 'module/styles';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      builder = SassBuilder(includePaths: ['search_path']);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import.changeExtension('.css')
          ]));
      expect(reader.assetsRead, containsAll([primary, import]));
    });

    test('consults include path for partials', () async {
      var primary = makeAssetId('a|lib/syles.scss');
      var import = makeAssetId('a|search_path/module/_styles.scss');
      var inputs = {
        primary: '''@import 'module/styles';''',
        import: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import, inputs[import]);

      builder = SassBuilder(includePaths: ['search_path']);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import]));
    });

    test('uses first match in an include path list', () async {
      var primary = makeAssetId('a|lib/syles.scss');
      var importA = makeAssetId('a|search_path_a/module/_styles.scss');
      var importB = makeAssetId('a|search_path_b/module/_styles.scss');

      var inputs = {
        primary: '''@import 'module/styles';''',
        importA: '''/* no imports A */''',
        importB: '''/* no imports B */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(importA, inputs[importA]);
      reader.cacheStringAsset(importB, inputs[importB]);

      builder = SassBuilder(includePaths: ['search_path_a', 'search_path_b']);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, importA]));
    });

    test('import from include path uses local file first', () async {
      var primary = makeAssetId('a|lib/syles.scss');
      var importA = makeAssetId('a|search_path_a/module/_styles.scss');
      var importAAdded = makeAssetId('a|search_path_a/module/_added_file.scss');
      var importB = makeAssetId('a|search_path_b/module/_my_styles.scss');
      var importBAdded = makeAssetId('a|search_path_b/module/_added_file.scss');

      var inputs = {
        primary: '''@import 'module/my_styles';''',
        importA: '''/* no imports A */''',
        importAAdded: '''/* no imports A Added */''',
        importB: '''@import 'added_file';''',
        importBAdded: '''/* no imports B Added */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(importA, inputs[importA]);
      reader.cacheStringAsset(importAAdded, inputs[importAAdded]);
      reader.cacheStringAsset(importB, inputs[importB]);
      reader.cacheStringAsset(importBAdded, inputs[importBAdded]);

      builder = SassBuilder(includePaths: ['search_path_a', 'search_path_b']);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, importB, importBAdded]));
      expect(reader.assetsRead, isNot(contains(importAAdded)));
    });

    test('.sass file import parsing', () async {
      var primary = makeAssetId('a|lib/styles.sass');
      var import1 = makeAssetId('a|lib/_more_styles.sass');
      var import2 = makeAssetId('a|lib/_even_more_styles.sass');
      var inputs = {
        primary: '''@import 'more_styles', "even_more_styles.sass"''',
        import1: '''@import even_more_styles''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });

    test('.sass file imports in other packages', () async {
      var primary = makeAssetId('a|lib/styles.sass');
      var import1 = makeAssetId('b|lib/_more_styles.sass');
      var import2 = makeAssetId('b|lib/_even_more_styles.sass');
      var inputs = {
        primary:
            '''@import package:b/more_styles, package:b/even_more_styles.sass''',
        import1: '''@import "even_more_styles"''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(writer.assets.keys, equals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });

    test('multiple .sass imports in multiple blocks', () async {
      var primary = makeAssetId('a|lib/styles.sass');
      var import1 = makeAssetId('b|lib/more_styles.sass');
      var import2 = makeAssetId('a|lib/_more_styles.sass');
      var inputs = {
        primary: '''@import 'package:b/more_styles'
@import 'more_styles' ''',
        import1: '''/* no imports */''',
        import2: '''/* no imports */''',
      };

      reader.cacheStringAsset(primary, inputs[primary]);
      reader.cacheStringAsset(import1, inputs[import1]);
      reader.cacheStringAsset(import2, inputs[import2]);

      await runBuilder(builder, [primary], reader, writer, null);

      expect(writer.assets.keys,
          unorderedEquals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });
  });
}
