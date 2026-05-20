/// A native Android media codec capability reported by the device.
class MediaCodecCapability {
  /// Creates a media codec capability description.
  const MediaCodecCapability({
    required this.name,
    required this.isEncoder,
    required this.supportedTypes,
    required this.isHardwareAccelerated,
    required this.isSoftwareOnly,
    required this.isVendor,
    required this.supportedVideoTypes,
    required this.supportedAudioTypes,
  });

  /// The codec name reported by Android.
  final String name;

  /// Whether this codec encodes media.
  final bool isEncoder;

  /// MIME types supported by this codec.
  final List<String> supportedTypes;

  /// Whether Android reports this codec as hardware accelerated.
  final bool isHardwareAccelerated;

  /// Whether Android reports this codec as software only.
  final bool isSoftwareOnly;

  /// Whether Android reports this codec as vendor provided.
  final bool isVendor;

  /// Supported video MIME types.
  final List<String> supportedVideoTypes;

  /// Supported audio MIME types.
  final List<String> supportedAudioTypes;

  /// Creates a [MediaCodecCapability] from a map returned by the native platform.
  factory MediaCodecCapability.fromMap(Map<Object?, Object?> map) {
    return MediaCodecCapability(
      name: _readString(map, 'name'),
      isEncoder: _readBool(map, 'isEncoder'),
      supportedTypes: _readStringList(map, 'supportedTypes'),
      isHardwareAccelerated: _readBool(map, 'isHardwareAccelerated'),
      isSoftwareOnly: _readBool(map, 'isSoftwareOnly'),
      isVendor: _readBool(map, 'isVendor'),
      supportedVideoTypes: _readStringList(map, 'supportedVideoTypes'),
      supportedAudioTypes: _readStringList(map, 'supportedAudioTypes'),
    );
  }

  /// Converts this codec capability to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'name': name,
      'isEncoder': isEncoder,
      'supportedTypes': supportedTypes,
      'isHardwareAccelerated': isHardwareAccelerated,
      'isSoftwareOnly': isSoftwareOnly,
      'isVendor': isVendor,
      'supportedVideoTypes': supportedVideoTypes,
      'supportedAudioTypes': supportedAudioTypes,
    };
  }

  /// Returns a readable string containing all codec fields.
  @override
  String toString() {
    return 'MediaCodecCapability('
        'name: $name, '
        'isEncoder: $isEncoder, '
        'supportedTypes: $supportedTypes, '
        'isHardwareAccelerated: $isHardwareAccelerated, '
        'isSoftwareOnly: $isSoftwareOnly, '
        'isVendor: $isVendor, '
        'supportedVideoTypes: $supportedVideoTypes, '
        'supportedAudioTypes: $supportedAudioTypes'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }

  static List<String> _readStringList(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! List<Object?>) {
      return <String>[];
    }

    final List<String> values = <String>[];
    for (final Object? item in value) {
      if (item is String && item.isNotEmpty) {
        values.add(item);
      }
    }
    return values;
  }
}
