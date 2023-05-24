import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:sass_builder/sass_builder.dart';
import 'package:source_maps/source_maps.dart';
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
    late SassBuilder builder;
    late InMemoryAssetWriter writer;
    late InMemoryAssetReader reader;

    setUp(() {
      builder = SassBuilder();
      reader = InMemoryAssetReader();
      writer = InMemoryAssetWriter();
    });

    test('no imports, one read and one write', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var inputs = {
        primary: '/* no imports */',
      };
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

      await runBuilder(builder, inputs.keys, reader, writer, null);

      expect(
          writer.assets.keys,
          unorderedEquals([
            primary.changeExtension('.css'),
            import1.changeExtension('.css')
          ]));

      expect(reader.assetsRead, containsAll([primary, import1, import2]));
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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

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
      reader.cacheAll(inputs);

      await runBuilder(builder, [primary], reader, writer, null);

      expect(writer.assets.keys,
          unorderedEquals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });

    test('supports @use syntax for modular imports', () async {
      var primary = makeAssetId('a|lib/styles.scss');
      var import1 = makeAssetId('b|lib/more_styles.sass');
      var import2 = makeAssetId('a|lib/_more_styles.sass');
      var inputs = {
        primary: '''
            @use 'package:b/more_styles' as a;
            @use 'more_styles' as b;
          ''',
        import1: '''/* no imports */''',
        import2: '''/* no imports */''',
      };
      reader.cacheAll(inputs);

      await runBuilder(builder, [primary], reader, writer, null);

      expect(writer.assets.keys,
          unorderedEquals([primary.changeExtension('.css')]));
      expect(reader.assetsRead, containsAll([primary, import1, import2]));
    });
  });

  test('can generate source maps', () async {
    final writer = InMemoryAssetWriter();

    await testBuilder(
      SassBuilder(generateSourceMaps: true),
      {
        'a|web/styles.scss': '''
          @use 'package:b/more_styles';

          .foo { color: blue; }
        ''',
        'b|lib/more_styles.scss': '''
          .bar { color: red; }
        ''',
      },
      writer: writer,
      onLog: (record) => fail('Unexpected builder log: $record'),
    );

    final generatedCss =
        utf8.decode(writer.assets[makeAssetId('a|web/styles.css')]!);
    expect(generatedCss, endsWith('/*# sourceMappingURL=styles.css.map */\n'));

    final decoded = json
        .fuse(utf8)
        .decode(writer.assets[makeAssetId('a|web/styles.css.map')]!);
    final sourceMaps = SingleMapping.fromJson((decoded as Map).cast());
    final sources = sourceMaps.urls;

    expect(sources, hasLength(2));
    expect(sources, contains('styles.scss'));
    expect(sources, contains('packages/b/more_styles.scss'));
  });

  test('does not create source maps by default', () {
    return testBuilder(
      sassBuilder(BuilderOptions.forRoot),
      {
        'a|web/styles.scss': '''
          .foo { color: blue; }
        ''',
      },
      outputs: {
        // should be compiled to css, but without referencing a source mapping
        // url.
        'a|web/styles.css': predicate((List<int> bytes) {
          return !utf8.decode(bytes).contains('sourceMappingURL');
        }),
        // no .css.map file should be generated.
      },
      onLog: (record) => fail('Unexpected builder log: $record'),
    );
  });

  test('warns about invalid output style option', () {
    return testBuilder(
      sassBuilder(BuilderOptions({'outputStyle': 'invalid'}, isRoot: true)),
      {
        'a|web/styles.scss': '''
          .foo { color: blue; }
        ''',
      },
      outputs: {'a|web/styles.css': anything},
      onLog: expectAsync1((record) {
        expect(
            record.message,
            'Unknown outputStyle provided: "invalid". Supported values are: '
            '"expanded" and "compressed". The default value of "expanded" will '
            'be used.');
      }),
    );
  });
}

extension on InMemoryAssetReader {
  void cacheAll(Map<AssetId, String> contents) {
    contents.forEach(cacheStringAsset);
  }
}
