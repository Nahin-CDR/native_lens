import 'camera_capability.dart';
import 'compatibility_summary.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_platform_interface.dart';
import 'native_lens_report.dart';
import 'native_sensor.dart';
import 'network_capability.dart';
import 'network_speed_sample.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';

export 'camera_capability.dart';
export 'compatibility_summary.dart';
export 'display_info.dart';
export 'media_codec_capability.dart';
export 'native_sensor.dart';
export 'native_lens_report.dart';
export 'network_capability.dart';
export 'network_speed_sample.dart';
export 'platform_summary.dart';
export 'power_state.dart';
export 'system_feature.dart';

/// Entry point for reading basic native Android information.
class NativeLens {
  /// Returns a summary of the Android platform running the app.
  Future<PlatformSummary> getPlatformSummary() {
    return NativeLensPlatform.instance.getPlatformSummary();
  }

  /// Returns the native Android system features reported by the device.
  Future<List<SystemFeature>> getSystemFeatures() {
    return NativeLensPlatform.instance.getSystemFeatures();
  }

  /// Returns the native Android sensors reported by the device.
  Future<List<NativeSensor>> getSensors() {
    return NativeLensPlatform.instance.getSensors();
  }

  /// Returns native Android display capabilities for the active display.
  Future<DisplayInfo> getDisplayInfo() {
    return NativeLensPlatform.instance.getDisplayInfo();
  }

  /// Returns native Android media codec capabilities reported by the device.
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return NativeLensPlatform.instance.getMediaCodecs();
  }

  /// Returns native Android Camera2 capabilities reported by the device.
  Future<List<CameraCapability>> getCameraCapabilities() {
    return NativeLensPlatform.instance.getCameraCapabilities();
  }

  /// Returns native Android battery and power runtime state.
  Future<PowerState> getPowerState() {
    return NativeLensPlatform.instance.getPowerState();
  }

  /// Returns native Android network capability information for the active network.
  Future<NetworkCapability> getNetworkCapability() {
    return NativeLensPlatform.instance.getNetworkCapability();
  }

  /// Generates a complete snapshot report from the existing NativeLens APIs.
  ///
  /// This method does not call any new native Android API. It collects the
  /// current platform, feature, sensor, display, media, camera, power, and
  /// network snapshots into one readable [NativeLensReport].
  Future<NativeLensReport> generateReport() async {
    final PlatformSummary platformSummary = await getPlatformSummary();
    final List<SystemFeature> systemFeatures = await getSystemFeatures();
    final List<NativeSensor> sensors = await getSensors();
    final DisplayInfo displayInfo = await getDisplayInfo();
    final List<MediaCodecCapability> mediaCodecs = await getMediaCodecs();
    final List<CameraCapability> cameraCapabilities =
        await getCameraCapabilities();
    final PowerState powerState = await getPowerState();
    final NetworkCapability networkCapability = await getNetworkCapability();

    return NativeLensReport(
      platformSummary: platformSummary,
      systemFeatures: systemFeatures,
      sensors: sensors,
      displayInfo: displayInfo,
      mediaCodecs: mediaCodecs,
      cameraCapabilities: cameraCapabilities,
      powerState: powerState,
      networkCapability: networkCapability,
      generatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Analyzes the latest NativeLens report with simple offline rules.
  ///
  /// This method calls [generateReport] and does all compatibility analysis in
  /// Dart. It does not call a backend, paid service, or remote analysis API.
  Future<CompatibilitySummary> analyzeCompatibility() async {
    final NativeLensReport report = await generateReport();
    final List<String> recommendations = <String>[];
    final List<String> warnings = <String>[];
    int score = 100;

    final String powerRiskLevel = _analyzePowerRisk(report, warnings);
    if (powerRiskLevel == 'High') {
      score -= 20;
    } else if (powerRiskLevel == 'Medium') {
      score -= 10;
    }

    final String networkRiskLevel = _analyzeNetworkRisk(report, warnings);
    if (networkRiskLevel == 'High') {
      score -= 20;
    } else if (networkRiskLevel == 'Medium') {
      score -= 10;
    }

    final String mediaCapabilityLevel = _analyzeMediaCapability(
      report,
      recommendations,
    );
    if (mediaCapabilityLevel == 'Low') {
      score -= 15;
    } else if (mediaCapabilityLevel == 'Medium') {
      score -= 5;
    }

    final String cameraCapabilityLevel = _analyzeCameraCapability(
      report,
      warnings,
    );
    if (cameraCapabilityLevel == 'Low') {
      score -= 15;
    } else if (cameraCapabilityLevel == 'Medium') {
      score -= 5;
    }

    final String displayCapabilityLevel = _analyzeDisplayCapability(
      report,
      recommendations,
    );
    if (displayCapabilityLevel == 'Low') {
      score -= 5;
    }

    score += _sensorScoreBonus(report, recommendations);
    final int overallScore = score.clamp(0, 100);

    return CompatibilitySummary(
      overallScore: overallScore,
      overallLevel: _getOverallLevel(overallScore),
      powerRiskLevel: powerRiskLevel,
      networkRiskLevel: networkRiskLevel,
      mediaCapabilityLevel: mediaCapabilityLevel,
      cameraCapabilityLevel: cameraCapabilityLevel,
      displayCapabilityLevel: displayCapabilityLevel,
      recommendations: recommendations,
      warnings: warnings,
      generatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Emits native Android network capability updates as the active network changes.
  ///
  /// This stream listens to Android network callbacks so Wi-Fi, mobile data,
  /// VPN, and flight mode changes can update the app without a manual refresh.
  Stream<NetworkCapability> get networkCapabilityStream {
    return NativeLensPlatform.instance.networkCapabilityStream;
  }

  /// Emits app-level upload and download speed samples once per second.
  ///
  /// This measures this app's Android UID traffic, not full device internet
  /// speed and not device-wide network usage.
  Stream<NetworkSpeedSample> get networkSpeedStream {
    return NativeLensPlatform.instance.networkSpeedStream;
  }

  String _analyzePowerRisk(NativeLensReport report, List<String> warnings) {
    final PowerState powerState = report.powerState;

    if (powerState.batteryLevel <= 15 || powerState.isPowerSaveMode) {
      warnings.add(
        'Power risk is high because the battery is low or power saver is on.',
      );
      return 'High';
    }

    if (powerState.batteryLevel <= 30) {
      warnings.add('Battery is getting low. Consider reducing heavy work.');
      return 'Medium';
    }

    return 'Low';
  }

  String _analyzeNetworkRisk(NativeLensReport report, List<String> warnings) {
    final NetworkCapability networkCapability = report.networkCapability;

    if (!networkCapability.isConnected) {
      warnings.add('Network is disconnected.');
      return 'High';
    }

    if (!networkCapability.isValidated) {
      warnings.add(
        'Network is connected but Android has not validated internet access.',
      );
      return 'Medium';
    }

    return 'Low';
  }

  String _analyzeMediaCapability(
    NativeLensReport report,
    List<String> recommendations,
  ) {
    final bool hasHevcEncoder = _hasEncoderForType(report, 'video/hevc');
    final bool hasH264Encoder = _hasEncoderForType(report, 'video/avc');

    if (!hasHevcEncoder) {
      recommendations.add('HEVC encoder is unavailable. Use H.264 fallback.');
    }

    if (hasHevcEncoder && hasH264Encoder) {
      return 'High';
    }

    if (hasH264Encoder || hasHevcEncoder) {
      return 'Medium';
    }

    return 'Low';
  }

  String _analyzeCameraCapability(
    NativeLensReport report,
    List<String> warnings,
  ) {
    if (report.cameraCapabilities.isEmpty) {
      warnings.add('No cameras were reported by Android.');
      return 'Low';
    }

    final bool hasAdvancedCamera = report.cameraCapabilities.any((
      CameraCapability camera,
    ) {
      final bool hasAdvancedHardware =
          camera.hardwareLevel == 'Full' || camera.hardwareLevel == 'Level 3';

      return hasAdvancedHardware &&
          camera.supportsRawCapture &&
          camera.supportsManualSensor;
    });

    if (hasAdvancedCamera) {
      return 'High';
    }

    final bool hasLimitedCamera = report.cameraCapabilities.any((
      CameraCapability camera,
    ) {
      return camera.hardwareLevel == 'Limited' ||
          camera.hardwareLevel == 'Legacy';
    });

    if (hasLimitedCamera) {
      warnings.add('Camera hardware is limited on at least one camera.');
      return 'Low';
    }

    return 'Medium';
  }

  String _analyzeDisplayCapability(
    NativeLensReport report,
    List<String> recommendations,
  ) {
    final bool supportsHighRefresh = report.displayInfo.supportedRefreshRates
        .any((double refreshRate) => refreshRate >= 90);

    if (supportsHighRefresh || report.displayInfo.refreshRate >= 90) {
      recommendations.add(
        'High refresh display available. Consider 90Hz or 120Hz UI support.',
      );
      return 'High';
    }

    if (report.displayInfo.refreshRate >= 60) {
      return 'Medium';
    }

    return 'Low';
  }

  int _sensorScoreBonus(NativeLensReport report, List<String> recommendations) {
    if (report.sensors.length >= 10) {
      recommendations.add('Many sensors are available for richer experiences.');
      return 5;
    }

    return 0;
  }

  bool _hasEncoderForType(NativeLensReport report, String mimeType) {
    return report.mediaCodecs.any((MediaCodecCapability codec) {
      return codec.isEncoder && codec.supportedTypes.contains(mimeType);
    });
  }

  String _getOverallLevel(int score) {
    if (score >= 85) {
      return 'Excellent';
    }

    if (score >= 70) {
      return 'Good';
    }

    if (score >= 50) {
      return 'Fair';
    }

    return 'Limited';
  }
}
