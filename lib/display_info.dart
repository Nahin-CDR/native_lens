/// Native display information reported by the device.
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
    this.widthPoints,
    this.heightPoints,
    this.nativeScale,
    this.nativeWidthPixels,
    this.nativeHeightPixels,
    this.brightness,
    this.isIosNative = false,
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

  /// The display width in logical points, when provided by the platform.
  final double? widthPoints;

  /// The display height in logical points, when provided by the platform.
  final double? heightPoints;

  /// The native display scale, when safely available.
  final double? nativeScale;

  /// The native display width in physical pixels, when safely available.
  final int? nativeWidthPixels;

  /// The native display height in physical pixels, when safely available.
  final int? nativeHeightPixels;

  /// The current screen brightness, usually in the range 0.0 to 1.0.
  final double? brightness;

  /// Whether this display information came from the iOS native implementation.
  final bool isIosNative;

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
      widthPoints: _readOptionalDouble(map, 'widthPoints'),
      heightPoints: _readOptionalDouble(map, 'heightPoints'),
      nativeScale: _readOptionalDouble(map, 'nativeScale'),
      nativeWidthPixels: _readOptionalInt(map, 'nativeWidthPixels'),
      nativeHeightPixels: _readOptionalInt(map, 'nativeHeightPixels'),
      brightness: _readOptionalDouble(map, 'brightness'),
      isIosNative: _readBool(map, 'isIosNative'),
    );
  }

  /// Converts this display information to a map using the native field names.
  Map<String, Object> toMap() {
    final Map<String, Object> map = <String, Object>{
      'widthPixels': widthPixels,
      'heightPixels': heightPixels,
      'density': density,
      'densityDpi': densityDpi,
      'refreshRate': refreshRate,
      'supportedRefreshRates': supportedRefreshRates,
      'isHdrSupported': isHdrSupported,
      'supportedHdrTypes': supportedHdrTypes,
      'isIosNative': isIosNative,
    };

    void addOptional(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    addOptional('widthPoints', widthPoints);
    addOptional('heightPoints', heightPoints);
    addOptional('nativeScale', nativeScale);
    addOptional('nativeWidthPixels', nativeWidthPixels);
    addOptional('nativeHeightPixels', nativeHeightPixels);
    addOptional('brightness', brightness);

    return map;
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
        'supportedHdrTypes: $supportedHdrTypes, '
        'widthPoints: $widthPoints, '
        'heightPoints: $heightPoints, '
        'nativeScale: $nativeScale, '
        'nativeWidthPixels: $nativeWidthPixels, '
        'nativeHeightPixels: $nativeHeightPixels, '
        'brightness: $brightness, '
        'isIosNative: $isIosNative'
        ')';
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return null;
  }

  static double _readDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static double? _readOptionalDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
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
