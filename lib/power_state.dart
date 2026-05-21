/// Native Android battery and power state reported by the device.
class PowerState {
  /// Creates a power state description.
  const PowerState({
    required this.batteryLevel,
    required this.isCharging,
    required this.chargingSource,
    required this.batteryHealth,
    required this.batteryStatus,
    required this.batteryTemperatureCelsius,
    required this.isPowerSaveMode,
    required this.isIgnoringBatteryOptimizations,
  });

  /// The battery level percentage from 0 to 100, or 0 when unavailable.
  final int batteryLevel;

  /// Whether Android reports that the battery is charging or full.
  final bool isCharging;

  /// The readable charging source, such as AC, USB, Wireless, or Not charging.
  final String chargingSource;

  /// The readable battery health reported by Android.
  final String batteryHealth;

  /// The readable battery status reported by Android.
  final String batteryStatus;

  /// The battery temperature in degrees Celsius.
  final double batteryTemperatureCelsius;

  /// Whether Android power saver mode is currently enabled.
  final bool isPowerSaveMode;

  /// Whether this app is ignoring Android battery optimizations.
  final bool isIgnoringBatteryOptimizations;

  /// Creates a [PowerState] from a map returned by the native platform.
  factory PowerState.fromMap(Map<Object?, Object?> map) {
    return PowerState(
      batteryLevel: _readInt(map, 'batteryLevel'),
      isCharging: _readBool(map, 'isCharging'),
      chargingSource: _readString(map, 'chargingSource'),
      batteryHealth: _readString(map, 'batteryHealth'),
      batteryStatus: _readString(map, 'batteryStatus'),
      batteryTemperatureCelsius: _readDouble(map, 'batteryTemperatureCelsius'),
      isPowerSaveMode: _readBool(map, 'isPowerSaveMode'),
      isIgnoringBatteryOptimizations: _readBool(
        map,
        'isIgnoringBatteryOptimizations',
      ),
    );
  }

  /// Converts this power state to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'chargingSource': chargingSource,
      'batteryHealth': batteryHealth,
      'batteryStatus': batteryStatus,
      'batteryTemperatureCelsius': batteryTemperatureCelsius,
      'isPowerSaveMode': isPowerSaveMode,
      'isIgnoringBatteryOptimizations': isIgnoringBatteryOptimizations,
    };
  }

  /// Returns a readable string containing all power fields.
  @override
  String toString() {
    return 'PowerState('
        'batteryLevel: $batteryLevel, '
        'isCharging: $isCharging, '
        'chargingSource: $chargingSource, '
        'batteryHealth: $batteryHealth, '
        'batteryStatus: $batteryStatus, '
        'batteryTemperatureCelsius: $batteryTemperatureCelsius, '
        'isPowerSaveMode: $isPowerSaveMode, '
        'isIgnoringBatteryOptimizations: $isIgnoringBatteryOptimizations'
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

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }
}
