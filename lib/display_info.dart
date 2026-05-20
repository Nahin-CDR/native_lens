/// Native Android display information reported by the device.
class DisplayInfo {
  /// Creates a display information description.
  const DisplayInfo({
    required this.widthPixels,
    required this.heightPixels,
    required this.density,
    required this.densityDpi,
    required this.refreshRate,
    required this.supportedRefreshRates,
    required this.isHdrSupported,
    required this.supportedHdrTypes,
  });

  /// The display width in physical pixels.
  final int widthPixels;

  /// The display height in physical pixels.
  final int heightPixels;

  /// The logical display density scale.
  final double density;

  /// The display density in dots per inch.
  final int densityDpi;

  /// The current display refresh rate in hertz.
  final double refreshRate;

  /// Refresh rates supported by the active display, in hertz.
  final List<double> supportedRefreshRates;

  /// Whether the active display reports HDR support.
  final bool isHdrSupported;

  /// Readable names for supported HDR types.
  final List<String> supportedHdrTypes;

  /// Creates a [DisplayInfo] from a map returned by the native platform.
  factory DisplayInfo.fromMap(Map<Object?, Object?> map) {
    return DisplayInfo(
      widthPixels: _readInt(map, 'widthPixels'),
      heightPixels: _readInt(map, 'heightPixels'),
      density: _readDouble(map, 'density'),
      densityDpi: _readInt(map, 'densityDpi'),
      refreshRate: _readDouble(map, 'refreshRate'),
      supportedRefreshRates: _readDoubleList(map, 'supportedRefreshRates'),
      isHdrSupported: _readBool(map, 'isHdrSupported'),
      supportedHdrTypes: _readStringList(map, 'supportedHdrTypes'),
    );
  }

  /// Converts this display information to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'widthPixels': widthPixels,
      'heightPixels': heightPixels,
      'density': density,
      'densityDpi': densityDpi,
      'refreshRate': refreshRate,
      'supportedRefreshRates': supportedRefreshRates,
      'isHdrSupported': isHdrSupported,
      'supportedHdrTypes': supportedHdrTypes,
    };
  }

  /// Returns a readable string containing all display fields.
  @override
  String toString() {
    return 'DisplayInfo('
        'widthPixels: $widthPixels, '
        'heightPixels: $heightPixels, '
        'density: $density, '
        'densityDpi: $densityDpi, '
        'refreshRate: $refreshRate, '
        'supportedRefreshRates: $supportedRefreshRates, '
        'isHdrSupported: $isHdrSupported, '
        'supportedHdrTypes: $supportedHdrTypes'
        ')';
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static double _readDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }

  static List<double> _readDoubleList(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! List<Object?>) {
      return <double>[];
    }

    final List<double> values = <double>[];
    for (final Object? item in value) {
      if (item is num) {
        values.add(item.toDouble());
      }
    }
    return values;
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
