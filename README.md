[![Build status](https://github.com/dart-league/sass_builder/actions/workflows/dart.yml/badge.svg)](https://github.com/dart-league/sass_builder/actions/workflows/dart.yml)

`package:sass_builder` transpiles Sass files using the [build][1] package and
the [Dart implementation][2] of [Sass][3].

[1]: https://github.com/dart-lang/build
[2]: https://github.com/sass/dart-sass
[3]: https://sass-lang.com/dart-sass/

## Usage

1\. Add `build_runner` and `sass_builder` as dev dependencies
    in your `pubspec.yaml` file:

```shell
dart pub add dev:build_runner dev:sass_builder
```

If you want to use any packages that provide source sass files,
add them as normal pub dependencies.
For example, if you want to use styles from `package:bootstrap_sass`:

```shell
dart pub add bootstrap_sass
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

* `outputStyle`: Supports `expanded` or `compressed`.
  Defaults to `expanded` in dev mode, and `compressed` in release mode.
* `sourceMaps`: Whether to emit source maps for compiled CSS.
  Defaults to `true` in development mode and to `false` in release mode.

Example that compresses output in dev mode:

```yaml
targets:
  $default:
    builders:
      sass_builder:
        options:
          outputStyle: compressed
```
