import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/sass_builder.dart';

var _graph = new PackageGraph.forThisPackage();

BuildAction get sassBuildAction =>
    new BuildAction(
        new SassBuilder(),
        _graph.root.name,
        inputs: ['**/*.scss', '**/*.sass']);