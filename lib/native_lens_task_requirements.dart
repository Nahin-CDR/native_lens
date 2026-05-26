/// Developer-defined capability requirements for a custom NativeLens task.
class NativeLensTaskRequirements {
  /// Creates custom task requirements.
  const NativeLensTaskRequirements({
    this.requiresCamera = false,
    this.requiresMicrophone = false,
    this.requiresStableNetwork = false,
    this.requiresUnmeteredNetwork = false,
    this.requiresHevcEncoder = false,
    this.requiresMediaCodecs = false,
    this.requiredSensors = const <String>[],
    this.requiredSystemFeatures = const <String>[],
    this.minBatteryLevel,
    this.minRefreshRate,
    this.minCameraCount,
    this.minSensorCount,
    this.minCodecCount,
    this.allowPowerSaveMode = true,
  });

  /// Whether at least one camera capability is required.
  final bool requiresCamera;

  /// Whether microphone capability is required.
  final bool requiresMicrophone;

  /// Whether a connected and validated network is required.
  final bool requiresStableNetwork;

  /// Whether the active network must be unmetered.
  final bool requiresUnmeteredNetwork;

  /// Whether an HEVC encoder is required.
  final bool requiresHevcEncoder;

  /// Whether media codec capability is required.
  final bool requiresMediaCodecs;

  /// Sensor names or aliases required by the task.
  final List<String> requiredSensors;

  /// Native system feature names required by the task.
  final List<String> requiredSystemFeatures;

  /// Minimum battery percentage required by the task.
  final int? minBatteryLevel;

  /// Minimum display refresh rate required by the task.
  final double? minRefreshRate;

  /// Minimum number of cameras required by the task.
  final int? minCameraCount;

  /// Minimum number of sensors required by the task.
  final int? minSensorCount;

  /// Minimum number of media codecs required by the task.
  final int? minCodecCount;

  /// Whether power saver mode is acceptable for the task.
  final bool allowPowerSaveMode;

  /// Creates requirements from a map using stable field names.
  factory NativeLensTaskRequirements.fromMap(Map<Object?, Object?> map) {
    return NativeLensTaskRequirements(
      requiresCamera: _readBool(map, 'requiresCamera', defaultValue: false),
      requiresMicrophone: _readBool(
        map,
        'requiresMicrophone',
        defaultValue: false,
      ),
      requiresStableNetwork: _readBool(
        map,
        'requiresStableNetwork',
        defaultValue: false,
      ),
      requiresUnmeteredNetwork: _readBool(
        map,
        'requiresUnmeteredNetwork',
        defaultValue: false,
      ),
      requiresHevcEncoder: _readBool(
        map,
        'requiresHevcEncoder',
        defaultValue: false,
      ),
      requiresMediaCodecs: _readBool(
        map,
        'requiresMediaCodecs',
        defaultValue: false,
      ),
      requiredSensors: _readStringList(map, 'requiredSensors'),
      requiredSystemFeatures: _readStringList(map, 'requiredSystemFeatures'),
      minBatteryLevel: _readOptionalInt(map, 'minBatteryLevel'),
      minRefreshRate: _readOptionalDouble(map, 'minRefreshRate'),
      minCameraCount: _readOptionalInt(map, 'minCameraCount'),
      minSensorCount: _readOptionalInt(map, 'minSensorCount'),
      minCodecCount: _readOptionalInt(map, 'minCodecCount'),
      allowPowerSaveMode: _readBool(
        map,
        'allowPowerSaveMode',
        defaultValue: true,
      ),
    );
  }

  /// Serializes requirements to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'requiresCamera': requiresCamera,
      'requiresMicrophone': requiresMicrophone,
      'requiresStableNetwork': requiresStableNetwork,
      'requiresUnmeteredNetwork': requiresUnmeteredNetwork,
      'requiresHevcEncoder': requiresHevcEncoder,
      'requiresMediaCodecs': requiresMediaCodecs,
      'requiredSensors': requiredSensors,
      'requiredSystemFeatures': requiredSystemFeatures,
      'minBatteryLevel': minBatteryLevel,
      'minRefreshRate': minRefreshRate,
      'minCameraCount': minCameraCount,
      'minSensorCount': minSensorCount,
      'minCodecCount': minCodecCount,
      'allowPowerSaveMode': allowPowerSaveMode,
    };
  }

  @override
  String toString() {
    return 'NativeLensTaskRequirements('
        'requiresCamera: $requiresCamera, '
        'requiresMicrophone: $requiresMicrophone, '
        'requiresStableNetwork: $requiresStableNetwork, '
        'requiresUnmeteredNetwork: $requiresUnmeteredNetwork, '
        'requiresHevcEncoder: $requiresHevcEncoder, '
        'requiresMediaCodecs: $requiresMediaCodecs, '
        'requiredSensors: $requiredSensors, '
        'requiredSystemFeatures: $requiredSystemFeatures, '
        'minBatteryLevel: $minBatteryLevel, '
        'minRefreshRate: $minRefreshRate, '
        'minCameraCount: $minCameraCount, '
        'minSensorCount: $minSensorCount, '
        'minCodecCount: $minCodecCount, '
        'allowPowerSaveMode: $allowPowerSaveMode'
        ')';
  }

  static bool _readBool(
    Map<Object?, Object?> map,
    String key, {
    required bool defaultValue,
  }) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return null;
  }

  static double? _readOptionalDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
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
