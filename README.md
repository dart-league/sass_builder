# sass_builder

[![Build Status](https://travis-ci.org/dart-league/sass_builder.svg?branch=master)](https://travis-ci.org/dart-league/sass_builder)

Transpile sass files using the [build][1] package and the dart implementation
of [sass][2].

[1]: https://github.com/dart-lang/build
[2]: https://github.com/sass/dart-sass

## Usage

1\. Create a `pubspec.yaml` file containing the following code:

```yaml
dependencies:
  # (optional) depend on the latest version of packages providing sass sources
  bootstrap_sass: any
dev_dependencies:
  # update to the latest versions
  sass_builder: ^2.1.2
  build_runner: ^2.1.7
```

2\. Create `web/main.scss` containing the following code:

```scss
@use "sub";
@use "package:bootstrap_sass/scss/variables" as bootstrap;

.a {
  color: blue;
}

.c {
  color: bootstrap.$body-color;
}

```

3\. Create `web/_sub.scss` containing the following code:

```scss
.b {
  color: red;
}

```

4\. Create `web/index.html` containing the following code:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Sample</title>
    <link rel="stylesheet" href="main.css">
</head>
<body>
<div class="a">Some Text</div>
<div class="b">Some Text</div>
<div class="c">Some Text</div>
</body>
</html>
```

5\. Run `dart run build_runner serve` and then go to `localhost:8080` with a browser
 and check if the file `web/main.css` was generated containing:

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

### Builder Options

To configure options for the builder see the `build_config`
[README](https://github.com/dart-lang/build/blob/master/build_config/README.md).

* `outputStyle`: Supports `expanded` or `compressed`. Defaults to `expanded` in
  dev mode, and `compressed` in release mode.
* `sourceMaps`: Whether to emit source maps for compiled css. Defaults to
  `true` in development mode and to `false` in release mode.

Example that compresses output in dev mode:

```yaml
targets:
  $default:
    builders:
      sass_builder:
        options:
          outputStyle: compressed
```
