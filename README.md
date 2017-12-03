# sass_builder

Transpile sass files using the [build][1] package and the dart implementation
of [sass][2].

[1]: https://github.com/dart-lang/build
[2]: https://github.com/sass/dart-sass

## Usage

1\. Create a `pubspec.yaml` file containing the following code:

```yaml
dependencies:
    bootstrap_sass: any # this dependency is only for demo purposes
dev_dependencies:
    sass_builder: ^1.0.0 # update for the latest version
```

2\. Create `web/main.scss` containing the following code:

```scss
@import "sub";
@import "package:bootstrap_sass/scss/variables";

.a {
  color: blue;
}

.c {
  color: $body-color;
}
```

3\. Create `web/_sub.scss` containing the following code:

```scss
.b {
  color: red;
}
```

4\. Create `tool/build.dart` containing the following code:

```dart
import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/phase.dart';

Future main() async {
  await build([sassBuildAction], deleteFilesByDefault: true);
}

```

You can also create `tool/watch.dart` with the following code:

```dart
import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/phase.dart';

Future main() async {
  await watch([sassBuildAction], deleteFilesByDefault: true);
}

```

5\. Run either `tool/build.dart` or `tool/watch.dart` and the file `web/main.css`
    will be generated containing:

```css
.b {
  color: red;
}

.a {
  color: blue;
}

.c {
  color: #373a3c;
}

```

## Wrapped as a Pub Transformer

To automatically generate .css files when you run `pub build` or `pub serve`
you can add sass_builder as a transformer in your package.

In your `pubspec.yaml` add the following code:

```yaml
dependencies:
  sass_builder ^1.0.0 # update for the latest version
transformers:
- sass_builder
```

By default this will generate .css files for every non-partial .scss file in your project. You can customize the extension of the generated files with the `outputExtension` option:

```yaml
transformers:
- sass_builder:
    outputExtension: .scss.css
```
