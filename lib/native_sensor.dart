/// A native Android sensor reported by the device.
class NativeSensor {
  /// Creates a native sensor description.
  const NativeSensor({
    required this.name,
    required this.vendor,
    required this.type,
    required this.typeName,
    required this.version,
    required this.resolution,
    required this.maximumRange,
    required this.power,
    required this.minDelay,
    required this.maxDelay,
    required this.isWakeUpSensor,
  });

  /// The sensor name reported by Android.
  final String name;

  /// The sensor vendor reported by Android.
  final String vendor;

  /// The Android sensor type integer.
  final int type;

  /// A readable name for the Android sensor type.
  final String typeName;

  /// The sensor version reported by Android.
  final int version;

  /// The smallest change the sensor can measure.
  final double resolution;

  /// The maximum value the sensor can report.
  final double maximumRange;

  /// The sensor power usage in milliamps.
  final double power;

  /// The minimum delay between sensor events in microseconds.
  final int minDelay;

  /// The maximum delay between sensor events in microseconds.
  final int maxDelay;

  /// Whether this sensor can wake the device from sleep.
  final bool isWakeUpSensor;

  /// Creates a [NativeSensor] from a map returned by the native platform.
  factory NativeSensor.fromMap(Map<Object?, Object?> map) {
    return NativeSensor(
      name: _readString(map, 'name'),
      vendor: _readString(map, 'vendor'),
      type: _readInt(map, 'type'),
      typeName: _readString(map, 'typeName'),
      version: _readInt(map, 'version'),
      resolution: _readDouble(map, 'resolution'),
      maximumRange: _readDouble(map, 'maximumRange'),
      power: _readDouble(map, 'power'),
      minDelay: _readInt(map, 'minDelay'),
      maxDelay: _readInt(map, 'maxDelay'),
      isWakeUpSensor: _readBool(map, 'isWakeUpSensor'),
    );
  }

  /// Converts this sensor to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'name': name,
      'vendor': vendor,
      'type': type,
      'typeName': typeName,
      'version': version,
      'resolution': resolution,
      'maximumRange': maximumRange,
      'power': power,
      'minDelay': minDelay,
      'maxDelay': maxDelay,
      'isWakeUpSensor': isWakeUpSensor,
    };
  }

  /// Returns a readable string containing all sensor fields.
  @override
  String toString() {
    return 'NativeSensor('
        'name: $name, '
        'vendor: $vendor, '
        'type: $type, '
        'typeName: $typeName, '
        'version: $version, '
        'resolution: $resolution, '
        'maximumRange: $maximumRange, '
        'power: $power, '
        'minDelay: $minDelay, '
        'maxDelay: $maxDelay, '
        'isWakeUpSensor: $isWakeUpSensor'
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
}
