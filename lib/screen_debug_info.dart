/// Information used by the NativeLens screen trace debug utility.
class ScreenDebugInfo {
  /// Creates screen debug information for [NativeLensDebug] and [NativeLensScreenTrace].
  const ScreenDebugInfo({
    required this.screenName,
    required this.filePath,
    required this.routeName,
    this.extra,
  });

  /// The display name of the current screen.
  final String screenName;

  /// The source file path for the current screen.
  final String filePath;

  /// The route name associated with the current screen.
  final String routeName;

  /// Optional extra context for the screen trace.
  final String? extra;

  /// Converts this screen debug information into a map.
  Map<String, String?> toMap() {
    return <String, String?>{
      'screenName': screenName,
      'filePath': filePath,
      'routeName': routeName,
      'extra': extra,
    };
  }
}
