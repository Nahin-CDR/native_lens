/// A native Android system feature reported by the device.
class SystemFeature {
  /// Creates a system feature description.
  const SystemFeature({
    required this.name,
    required this.version,
    required this.isGlEsFeature,
  });

  /// The Android feature name.
  ///
  /// OpenGL ES entries may not have a standard Android feature name, so
  /// NativeLens uses a readable name for those entries.
  final String name;

  /// The Android feature version, when the platform reports one.
  final int? version;

  /// Whether this entry describes the device OpenGL ES support.
  final bool isGlEsFeature;

  /// Creates a [SystemFeature] from a map returned by the native platform.
  factory SystemFeature.fromMap(Map<Object?, Object?> map) {
    return SystemFeature(
      name: _readString(map, 'name'),
      version: _readOptionalInt(map, 'version'),
      isGlEsFeature: _readBool(map, 'isGlEsFeature'),
    );
  }

  /// Converts this feature to a map using the native field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'version': version,
      'isGlEsFeature': isGlEsFeature,
    };
  }

  /// Returns a readable string containing all feature fields.
  @override
  String toString() {
    return 'SystemFeature('
        'name: $name, '
        'version: $version, '
        'isGlEsFeature: $isGlEsFeature'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int && value > 0) {
      return value;
    }
    return null;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }
}
