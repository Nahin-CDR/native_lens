import 'package:flutter/foundation.dart';

import 'screen_debug_info.dart';

/// Utility helpers for debug-only screen trace printing in NativeLens.
class NativeLensDebug {
  NativeLensDebug._();

  /// Prints the screen debug trace only when assertions are enabled.
  static void printScreen(ScreenDebugInfo info) {
    assert(() {
      debugPrint(formatScreenTrace(info));
      return true;
    }());
  }

  /// Formats the screen debug trace into a readable multi-line string.
  static String formatScreenTrace(ScreenDebugInfo info) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('[NativeLens] Screen Debug')
      ..writeln('Screen: ${info.screenName}')
      ..writeln('File: ${info.filePath}')
      ..writeln('Route: ${info.routeName}');

    if (info.extra != null && info.extra!.isNotEmpty) {
      buffer.writeln('Extra: ${info.extra}');
    }

    return buffer.toString().trimRight();
  }
}
