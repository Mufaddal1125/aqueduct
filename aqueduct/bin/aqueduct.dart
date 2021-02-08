import 'dart:async';
import 'dart:io';

import 'package:aqueduct/src/cli/runner.dart';

Future main(List<String> args) async {
  print('[Aqueduct mufaddal1125]');
  final runner = Runner();
  final values = runner.options.parse(args);
  exitCode = await runner.process(values);
}

