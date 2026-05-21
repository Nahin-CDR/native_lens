/// A native Android Camera2 capability reported by the device.
class CameraCapability {
  /// Creates a Camera2 capability description.
  const CameraCapability({
    required this.cameraId,
    required this.lensFacing,
    required this.hardwareLevel,
    required this.hasFlash,
    required this.sensorOrientation,
    required this.supportsRawCapture,
    required this.supportsManualSensor,
    required this.supportsManualPostProcessing,
    required this.supportsAutoFocus,
    required this.supportsOpticalStabilization,
    required this.supportedFpsRanges,
  });

  /// The Android camera identifier.
  final String cameraId;

  /// Readable lens direction, such as Front, Back, or External.
  final String lensFacing;

  /// Readable Camera2 hardware support level.
  final String hardwareLevel;

  /// Whether this camera reports flash support.
  final bool hasFlash;

  /// Sensor orientation in degrees.
  final int sensorOrientation;

  /// Whether this camera supports RAW capture.
  final bool supportsRawCapture;

  /// Whether this camera supports manual sensor controls.
  final bool supportsManualSensor;

  /// Whether this camera supports manual post-processing controls.
  final bool supportsManualPostProcessing;

  /// Whether this camera reports autofocus modes beyond fixed focus.
  final bool supportsAutoFocus;

  /// Whether this camera reports optical image stabilization support.
  final bool supportsOpticalStabilization;

  /// Readable target frames-per-second ranges supported by this camera.
  final List<String> supportedFpsRanges;

  /// Creates a [CameraCapability] from a map returned by the native platform.
  factory CameraCapability.fromMap(Map<Object?, Object?> map) {
    return CameraCapability(
      cameraId: _readString(map, 'cameraId'),
      lensFacing: _readString(map, 'lensFacing'),
      hardwareLevel: _readString(map, 'hardwareLevel'),
      hasFlash: _readBool(map, 'hasFlash'),
      sensorOrientation: _readInt(map, 'sensorOrientation'),
      supportsRawCapture: _readBool(map, 'supportsRawCapture'),
      supportsManualSensor: _readBool(map, 'supportsManualSensor'),
      supportsManualPostProcessing: _readBool(
        map,
        'supportsManualPostProcessing',
      ),
      supportsAutoFocus: _readBool(map, 'supportsAutoFocus'),
      supportsOpticalStabilization: _readBool(
        map,
        'supportsOpticalStabilization',
      ),
      supportedFpsRanges: _readStringList(map, 'supportedFpsRanges'),
    );
  }

  /// Converts this camera capability to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'cameraId': cameraId,
      'lensFacing': lensFacing,
      'hardwareLevel': hardwareLevel,
      'hasFlash': hasFlash,
      'sensorOrientation': sensorOrientation,
      'supportsRawCapture': supportsRawCapture,
      'supportsManualSensor': supportsManualSensor,
      'supportsManualPostProcessing': supportsManualPostProcessing,
      'supportsAutoFocus': supportsAutoFocus,
      'supportsOpticalStabilization': supportsOpticalStabilization,
      'supportedFpsRanges': supportedFpsRanges,
    };
  }

  /// Returns a readable string containing all camera fields.
  @override
  String toString() {
    return 'CameraCapability('
        'cameraId: $cameraId, '
        'lensFacing: $lensFacing, '
        'hardwareLevel: $hardwareLevel, '
        'hasFlash: $hasFlash, '
        'sensorOrientation: $sensorOrientation, '
        'supportsRawCapture: $supportsRawCapture, '
        'supportsManualSensor: $supportsManualSensor, '
        'supportsManualPostProcessing: $supportsManualPostProcessing, '
        'supportsAutoFocus: $supportsAutoFocus, '
        'supportsOpticalStabilization: $supportsOpticalStabilization, '
        'supportedFpsRanges: $supportedFpsRanges'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
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
