import 'camera_capability.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_sensor.dart';
import 'network_capability.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';

/// A single snapshot report made from the existing NativeLens APIs.
class NativeLensReport {
  /// Creates a complete NativeLens snapshot report.
  const NativeLensReport({
    required this.platformSummary,
    required this.systemFeatures,
    required this.sensors,
    required this.displayInfo,
    required this.mediaCodecs,
    required this.cameraCapabilities,
    required this.powerState,
    required this.networkCapability,
    required this.generatedAtMillis,
  });

  /// Basic Android build and device information.
  final PlatformSummary platformSummary;

  /// Native Android system features reported by the device.
  final List<SystemFeature> systemFeatures;

  /// Native Android sensors reported by the device.
  final List<NativeSensor> sensors;

  /// Native Android display capabilities for the active display.
  final DisplayInfo displayInfo;

  /// Native Android media codec capabilities reported by the device.
  final List<MediaCodecCapability> mediaCodecs;

  /// Native Android Camera2 capabilities reported by the device.
  final List<CameraCapability> cameraCapabilities;

  /// Native Android battery and power runtime state.
  final PowerState powerState;

  /// Native Android network capability information for the active network.
  final NetworkCapability networkCapability;

  /// The time this report was generated, in milliseconds since epoch.
  final int generatedAtMillis;

  /// Converts this report to a map using the public model field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'platformSummary': platformSummary.toMap(),
      'systemFeatures': systemFeatures
          .map((SystemFeature feature) => feature.toMap())
          .toList(),
      'sensors': sensors.map((NativeSensor sensor) => sensor.toMap()).toList(),
      'displayInfo': displayInfo.toMap(),
      'mediaCodecs': mediaCodecs
          .map((MediaCodecCapability codec) => codec.toMap())
          .toList(),
      'cameraCapabilities': cameraCapabilities
          .map((CameraCapability camera) => camera.toMap())
          .toList(),
      'powerState': powerState.toMap(),
      'networkCapability': networkCapability.toMap(),
      'generatedAtMillis': generatedAtMillis,
    };
  }

  /// Returns a readable string with the report summary.
  @override
  String toString() {
    return 'NativeLensReport('
        'platformSummary: $platformSummary, '
        'systemFeatures: ${systemFeatures.length}, '
        'sensors: ${sensors.length}, '
        'displayInfo: $displayInfo, '
        'mediaCodecs: ${mediaCodecs.length}, '
        'cameraCapabilities: ${cameraCapabilities.length}, '
        'powerState: $powerState, '
        'networkCapability: $networkCapability, '
        'generatedAtMillis: $generatedAtMillis'
        ')';
  }
}
