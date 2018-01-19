When building with package `build_runner` you can view the output by specifying
an output directory. __Warning: If the directory already exists, the content
will be deleted.__

Example:

```
$ pub run build_runner build --output out
```

The output will be located in the directory
`out/packages/sass_builder_example`.

> The packages directory is hidden by default.
