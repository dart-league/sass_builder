# sass_builder

Transpile sass files using the "build" package.

## Usage

1. create `pubspec.yaml` containing next code:

```yaml
dependencies:
    bootstrap_sass: any # this dependency is only for demo purpose
dev_dependencies:
    sass_builder: 0.0.1 # change it for latest version
```

1\. create `web/main.scss` file and add next code:

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

2\. create `web/_sub.scss` file and add next code:

```scss
.b {
  color: red;
}
```

3\. create `tool/build.dart` file and add next code:

```dart
import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/phase.dart';

Future main() async {
  await build([sassBuildAction]);
}
```

you can also create `tool/watch.dart` file and add next code:

```dart
import 'dart:async';

import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/phase.dart';

Future main() async {
  await watch([sassBuildAction], deleteFilesByDefault: true);
}
```

4\. run either `tool/build.dart` or `tool/watch.dart` and then the file `web/main.css` will be generated containing next code:

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