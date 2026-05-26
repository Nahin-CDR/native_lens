import 'dart:io';

import 'package:native_lens/src/splash_tool.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runNativeLensSplash(arguments);
}
