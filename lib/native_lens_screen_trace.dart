import 'package:flutter/widgets.dart';

import 'native_lens_debug.dart';
import 'screen_debug_info.dart';

/// A widget wrapper that prints screen debug information during development.
///
/// The debug output is emitted only when asserts are enabled. In release
/// builds this widget simply returns its [child] without printing anything.
class NativeLensScreenTrace extends StatefulWidget {
  /// Creates a screen trace wrapper for debug builds.
  const NativeLensScreenTrace({
    super.key,
    required this.screenName,
    required this.filePath,
    required this.routeName,
    this.extra,
    required this.child,
  });

  /// The display name of the current screen.
  final String screenName;

  /// The source file path for the current screen.
  final String filePath;

  /// The route name associated with the current screen.
  final String routeName;

  /// Optional extra context for the screen trace.
  final String? extra;

  /// The widget below this wrapper in the tree.
  final Widget child;

  @override
  State<NativeLensScreenTrace> createState() => _NativeLensScreenTraceState();
}

class _NativeLensScreenTraceState extends State<NativeLensScreenTrace> {
  @override
  void initState() {
    super.initState();

    assert(() {
      NativeLensDebug.printScreen(
        ScreenDebugInfo(
          screenName: widget.screenName,
          filePath: widget.filePath,
          routeName: widget.routeName,
          extra: widget.extra,
        ),
      );
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
