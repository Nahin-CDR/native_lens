/// Native battery and power state reported by the device.
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
    this.batteryState,
    this.isBatteryMonitoringEnabled,
    this.isBatteryMonitoringAvailable,
    this.thermalState,
    this.isIosNative = false,
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

  /// Platform battery state, such as unknown, unplugged, charging, or full.
  final String? batteryState;

  /// Whether native battery monitoring is enabled for this reading.
  final bool? isBatteryMonitoringEnabled;

  /// Whether native battery monitoring currently has usable battery data.
  final bool? isBatteryMonitoringAvailable;

  /// Current thermal state, when safely available.
  final String? thermalState;

  /// Whether this power state came from the iOS native implementation.
  final bool isIosNative;

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
      batteryState: _readOptionalString(map, 'batteryState'),
      isBatteryMonitoringEnabled: _readOptionalBool(
        map,
        'isBatteryMonitoringEnabled',
      ),
      isBatteryMonitoringAvailable: _readOptionalBool(
        map,
        'isBatteryMonitoringAvailable',
      ),
      thermalState: _readOptionalString(map, 'thermalState'),
      isIosNative: _readBool(map, 'isIosNative'),
    );
  }

  /// Converts this power state to a map using the native field names.
  Map<String, Object> toMap() {
    final Map<String, Object> map = <String, Object>{
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'chargingSource': chargingSource,
      'batteryHealth': batteryHealth,
      'batteryStatus': batteryStatus,
      'batteryTemperatureCelsius': batteryTemperatureCelsius,
      'isPowerSaveMode': isPowerSaveMode,
      'isIgnoringBatteryOptimizations': isIgnoringBatteryOptimizations,
      'isIosNative': isIosNative,
    };

    void addOptional(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    addOptional('batteryState', batteryState);
    addOptional('isBatteryMonitoringEnabled', isBatteryMonitoringEnabled);
    addOptional('isBatteryMonitoringAvailable', isBatteryMonitoringAvailable);
    addOptional('thermalState', thermalState);

    return map;
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
        'isIgnoringBatteryOptimizations: $isIgnoringBatteryOptimizations, '
        'batteryState: $batteryState, '
        'isBatteryMonitoringEnabled: $isBatteryMonitoringEnabled, '
        'isBatteryMonitoringAvailable: $isBatteryMonitoringAvailable, '
        'thermalState: $thermalState, '
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

  static bool? _readOptionalBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return null;
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
