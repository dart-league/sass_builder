import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:sass_builder/sass_builder.dart';
import 'package:source_maps/source_maps.dart';
import 'package:test/test.dart';

void main() {
  /// These tests only verify which assets are read and written by the
  /// [SassBuilder]. This is to test the behavior of the AsyncImporter used to
  /// handle Dart package imports and perform all file IO through the
  /// build_step.
  ///
  /// In some cases additional dependencies are created on files that do not
  /// exists because Sass allows the user to omit the file extensions `.scss`
  /// or `.sass`, the partial prefix `_` or the file name altogether. These
  /// tests avoid testing for those dependencies that are created when probing
  /// for imports.
  ///
  /// These tests do not verify any output as that is determined by the Sass
  /// implementation.
  group('build IO tests', () {
    late SassBuilder builder;

    setUp(() {
      builder = SassBuilder();
    });

    test('no imports, one read and one write', () async {
      final result = await testBuilder(builder, {
        'a|lib/styles.scss': '/* no imports */',
      }, outputs: {
        'a|lib/styles.css': anything,
      });

      expect(result.readerWriter.testing.trackedExistingInputs,
          [makeAssetId('a|lib/styles.scss')]);
    });

    test('one relative partial import', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import '_more_styles.scss';''',
          'a|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, [
        makeAssetId('a|lib/_more_styles.scss'),
        makeAssetId('a|lib/styles.scss'),
      ]);
    });

    test('one relative partial import simplified name', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'more_styles';''',
          'a|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('a|lib/_more_styles.scss'),
      });
    });

    test('one relative import', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'foo/more_styles';''',
          'a|lib/foo/more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'a|lib/foo/more_styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('a|lib/foo/more_styles.scss'),
      });
    });

    test('one package import', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'package:b/more_styles';''',
          'b|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('b|lib/_more_styles.scss'),
      });
    });

    test('multiple imports in one block', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'more_styles';''',
          'b|lib/more_styles.scss': '''/* no imports */''',
          'a|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'b|lib/more_styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('b|lib/more_styles.scss'),
        makeAssetId('a|lib/_more_styles.scss'),
      });
    });

    test('multiple imports in multiple blocks', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'package:b/more_styles';'''
              '''@import 'more_styles';''',
          'b|lib/more_styles.scss': '''/* no imports */''',
          'a|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'b|lib/more_styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('b|lib/more_styles.scss'),
        makeAssetId('a|lib/_more_styles.scss'),
      });
    });

    test('transitive imports', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''@import 'package:b/styles';''',
          'b|lib/styles.scss': '''@import 'more_styles';''',
          'b|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'b|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('b|lib/styles.scss'),
        makeAssetId('b|lib/_more_styles.scss'),
      });
    });

    test('.sass file import parsing', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.sass':
              '''@import 'more_styles', "even_more_styles.sass"''',
          'a|lib/_more_styles.sass': '''@import "even_more_styles"''',
          'a|lib/_even_more_styles.sass': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.sass'),
        makeAssetId('a|lib/_more_styles.sass'),
        makeAssetId('a|lib/_even_more_styles.sass'),
      });
    });

    test('.sass file imports in other packages', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.sass':
              '''@import package:b/more_styles, package:b/even_more_styles.sass''',
          'b|lib/_more_styles.sass': '''@import "even_more_styles"''',
          'b|lib/_even_more_styles.sass': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.sass'),
        makeAssetId('b|lib/_more_styles.sass'),
        makeAssetId('b|lib/_even_more_styles.sass'),
      });
    });

    test('multiple .sass imports in multiple blocks', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.sass': '''@import 'package:b/more_styles'
@import 'more_styles' ''',
          'b|lib/more_styles.sass': '''/* no imports */''',
          'a|lib/_more_styles.sass': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'b|lib/more_styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.sass'),
        makeAssetId('b|lib/more_styles.sass'),
        makeAssetId('a|lib/_more_styles.sass'),
      });
    });

    test('supports @use syntax for modular imports', () async {
      final results = await testBuilder(
        builder,
        {
          'a|lib/styles.scss': '''
            @use 'package:b/more_styles' as a;
            @use 'more_styles' as b;
          ''',
          'b|lib/more_styles.scss': '''/* no imports */''',
          'a|lib/_more_styles.scss': '''/* no imports */''',
        },
        outputs: {
          'a|lib/styles.css': anything,
          'b|lib/more_styles.css': anything,
        },
      );

      expect(results.readerWriter.testing.trackedExistingInputs, {
        makeAssetId('a|lib/styles.scss'),
        makeAssetId('b|lib/more_styles.scss'),
        makeAssetId('a|lib/_more_styles.scss'),
      });
    });
  });

  test('can generate source maps', () async {
    await testBuilder(
      SassBuilder(generateSourceMaps: true),
      {
        'a|web/styles.scss': '''
          @use 'package:b/more_styles';

          .foo { color: blue; }
        ''',
        'b|lib/_more_styles.scss': '''
          .bar { color: red; }
        ''',
      },
      outputs: {
        'a|web/styles.css': decodedMatches(
            endsWith('/*# sourceMappingURL=styles.css.map */\n')),
        'a|web/styles.css.map': predicate((bytes) {
          final decoded = json.fuse(utf8).decode(bytes as List<int>);
          final sourceMaps = SingleMapping.fromJson((decoded as Map).cast());
          final sources = sourceMaps.urls;

          expect(sources, hasLength(2));
          expect(sources, contains('styles.scss'));
          expect(sources, contains('packages/b/_more_styles.scss'));
          return true;
        }),
      },
    );
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
    );
  });

  test('warns about invalid output style option', () async {
    final messages = <String>[];
    await testBuilder(
      sassBuilder(BuilderOptions({'outputStyle': 'invalid'}, isRoot: true)),
      {
        'a|web/styles.scss': '''
          .foo { color: blue; }
        ''',
      },
      outputs: {'a|web/styles.css': anything},
      onLog: (log) => messages.add(log.message),
    );

    expect(
      messages,
      anyElement(contains(
          'Unknown outputStyle provided: "invalid". Supported values are: '
          '"expanded" and "compressed". The default value of "expanded" will '
          'be used.')),
    );
  });
}

extension on ReaderWriterTesting {
  Set<AssetId> get trackedExistingInputs => inputsTracked.where(exists).toSet();
}
