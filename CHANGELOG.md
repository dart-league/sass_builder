## 2.1.3

* Widen version constrain on `build_config`.

## 2.1.2

### Maintenance Release

* Widen version constraints on dependencies: build and sass.
* Remove use of the deprecated `indented` parameter when compiling with sass.

## 2.1.1

* Set max SDK version to <3.0.0

## 2.1.0

* Output style is now `compressed` by default for release builds.

## 2.0.3

* Upgrade selected package dependencies.

## 2.0.2

* Fix bug where compiling Dart package imports in Windows environment would
  fail.

## 2.0.1

* Fix bug where `.sass` entrypoints were not being compiled with "indented"
  syntax.
* Remove all temp file creation. Files are now imported using a custom
  [AsyncImporter](https://github.com/sass/dart-sass/blob/0a9a503ae08b2e57b97d5e791024089986dd85c7/lib/src/importer/async.dart#L22).

## 2.0.0

### New Feature

* Add a builder which will clean up `.scss` and `.sass` sources for `--release`
  builds.

### Breaking Change

* Remove the pub transformer.

## 1.2.0

* Add option to configure output style. Supports `expanded` or `compressed` as
  provided by the Dart implementation of Sass. Defaults to `expanded`.
* Removed dev dependencies that were no longer used.

## 1.1.5

* Fix a bug where the class `Logger` conflicted with `sass`, causing a crash.

## 1.1.4

* Improve warning message when an imported file can not be found.

## 1.1.3

* Fix example and documentation
* Fix import sass files (fix #25)

## 1.1.2

* Widen `build` and `build_test` dependencies.
* Update example and add some instructions regarding `build_runner`.

## 1.1.1

* Fixed compatibility with `.sass` file compilation.
* Bump `sass` dependency to `^1.0.0-beta.4`.

## 1.1.0

* Support the latest version of `build_runner`.
* Align the logger name with the package name: `sass_builder`.
* Upgrade to `build` to `^0.11.1`.

## 1.0.1

* Support the latest version of `build_runner`.
* Align the logger name with the package name: `sass_builder`.
* Upgrade to `build` to `^0.10.2+1`.

## 1.0.0

* Write assets to temporary directory.

## 0.2.0

* Upgrade `build_runner` to version `^0.4.0`.

## 0.1.2

* Fix #2: keep trying to build removed `.scss`.

## 0.1.1

* Add missing import.

## 0.1.0

* Upgrade `build` to `^0.9.1` and `build_runner` to `^0.3.2`.

## 0.0.2

* Recompile main files after editing sub files.

## 0.0.1

* First version.
