import 'dart:convert';

/// Stable AI- and dataset-friendly row model for NativeLens snapshots.
class NativeLensDatasetRow {
  /// Creates a NativeLens dataset row.
  const NativeLensDatasetRow({
    required this.schemaVersion,
    required this.platform,
    required this.batteryLevel,
    required this.isCharging,
    required this.isPowerSaveMode,
    required this.networkConnected,
    required this.networkValidated,
    required this.networkMetered,
    required this.hasHevcEncoder,
    required this.maxRefreshRate,
    required this.cameraCount,
    required this.sensorCount,
    required this.codecCount,
    required this.overallScore,
    required this.riskLevel,
    required this.labelSource,
    required this.createdAtMillis,
  });

  /// Schema identifier for the row format.
  final String schemaVersion;

  /// Platform identifier. Supported values are `android` and `ios`.
  final String platform;

  /// Battery level from 0 to 100.
  final int batteryLevel;

  /// Whether the device is charging.
  final bool isCharging;

  /// Whether power save mode is enabled.
  final bool isPowerSaveMode;

  /// Whether the active network is connected.
  final bool networkConnected;

  /// Whether the active network has been validated.
  final bool networkValidated;

  /// Whether the active network is metered.
  final bool networkMetered;

  /// Whether the device advertises an HEVC encoder.
  final bool hasHevcEncoder;

  /// Maximum refresh rate reported by the device.
  final double maxRefreshRate;

  /// Number of camera capabilities detected.
  final int cameraCount;

  /// Number of sensors detected.
  final int sensorCount;

  /// Number of codecs detected.
  final int codecCount;

  /// Overall compatibility score from 0 to 100.
  final int overallScore;

  /// Current risk level.
  final String riskLevel;

  /// Source used to label the row.
  final String labelSource;

  /// Creation timestamp in milliseconds since epoch.
  final int createdAtMillis;

  /// Serializes the row to a map using stable field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'schemaVersion': schemaVersion,
      'platform': platform,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'isPowerSaveMode': isPowerSaveMode,
      'networkConnected': networkConnected,
      'networkValidated': networkValidated,
      'networkMetered': networkMetered,
      'hasHevcEncoder': hasHevcEncoder,
      'maxRefreshRate': maxRefreshRate,
      'cameraCount': cameraCount,
      'sensorCount': sensorCount,
      'codecCount': codecCount,
      'overallScore': overallScore,
      'riskLevel': riskLevel,
      'labelSource': labelSource,
      'createdAtMillis': createdAtMillis,
    };
  }

  /// Serializes the row to a JSON string.
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Returns whether this row satisfies the required validation rules.
  bool get isValid {
    return schemaVersion.isNotEmpty &&
        (platform == 'android' || platform == 'ios') &&
        batteryLevel >= 0 &&
        batteryLevel <= 100 &&
        (riskLevel == 'low' ||
            riskLevel == 'medium' ||
            riskLevel == 'high' ||
            riskLevel == 'unknown') &&
        createdAtMillis > 0;
  }

  @override
  String toString() {
    return 'NativeLensDatasetRow('
        'schemaVersion: $schemaVersion, '
        'platform: $platform, '
        'batteryLevel: $batteryLevel, '
        'isCharging: $isCharging, '
        'isPowerSaveMode: $isPowerSaveMode, '
        'networkConnected: $networkConnected, '
        'networkValidated: $networkValidated, '
        'networkMetered: $networkMetered, '
        'hasHevcEncoder: $hasHevcEncoder, '
        'maxRefreshRate: $maxRefreshRate, '
        'cameraCount: $cameraCount, '
        'sensorCount: $sensorCount, '
        'codecCount: $codecCount, '
        'overallScore: $overallScore, '
        'riskLevel: $riskLevel, '
        'labelSource: $labelSource, '
        'createdAtMillis: $createdAtMillis'
        ')';
  }
}
