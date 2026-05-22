/// Device orientation information reported by NativeLens.
class DeviceOrientationInfo {
  /// Creates a device orientation snapshot or stream event.
  const DeviceOrientationInfo({
    required this.orientationName,
    required this.rotationDegrees,
    required this.isPortrait,
    required this.isLandscape,
    required this.source,
    required this.timestampMillis,
  });

  /// The readable orientation name.
  ///
  /// Supported values include:
  /// `portraitUp`, `portraitDown`, `landscapeLeft`, `landscapeRight`,
  /// `faceUp`, `faceDown`, and `unknown`.
  final String orientationName;

  /// The raw orientation rotation degrees if available.
  final int rotationDegrees;

  /// Whether the orientation is classified as portrait.
  final bool isPortrait;

  /// Whether the orientation is classified as landscape.
  final bool isLandscape;

  /// The source of orientation data, such as `display` or `orientation`.
  final String source;

  /// The timestamp when this orientation snapshot was produced.
  final int timestampMillis;

  /// Converts this orientation information into a map for platform channel
  /// serialization.
  Map<String, Object> toMap() {
    return <String, Object>{
      'orientationName': orientationName,
      'rotationDegrees': rotationDegrees,
      'isPortrait': isPortrait,
      'isLandscape': isLandscape,
      'source': source,
      'timestampMillis': timestampMillis,
    };
  }

  /// Creates a [DeviceOrientationInfo] instance from a platform channel map.
  factory DeviceOrientationInfo.fromMap(Map<Object?, Object?> map) {
    return DeviceOrientationInfo(
      orientationName: map['orientationName'] as String? ?? 'unknown',
      rotationDegrees: map['rotationDegrees'] as int? ?? -1,
      isPortrait: map['isPortrait'] as bool? ?? false,
      isLandscape: map['isLandscape'] as bool? ?? false,
      source: map['source'] as String? ?? 'unknown',
      timestampMillis: map['timestampMillis'] as int? ?? 0,
    );
  }
}
