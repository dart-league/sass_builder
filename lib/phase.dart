import 'package:build_runner/build_runner.dart';
import 'package:sass_builder/sass_builder.dart';

var _graph = new PackageGraph.forThisPackage();

Phase get sassPhase => new Phase()..addAction(
    new SassBuilder(), new InputSet(_graph.root.name, ['**/*.scss', '**/*.sass']));