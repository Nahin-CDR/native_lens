import 'dart:io' show Platform;

import 'camera_capability.dart';
import 'compatibility_summary.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_dataset_row.dart';
import 'native_lens_platform_interface.dart';
import 'native_lens_report.dart';
import 'native_sensor.dart';
import 'native_task_risk_result.dart';
import 'network_capability.dart';
import 'network_speed_sample.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';
import 'device_orientation_info.dart';
import 'native_lens_task.dart';

export 'camera_capability.dart';
export 'compatibility_summary.dart';
export 'display_info.dart';
export 'media_codec_capability.dart';
export 'native_lens_dataset_exporter.dart';
export 'native_lens_dataset_row.dart';
export 'native_lens_task.dart';
export 'native_sensor.dart';
export 'native_lens_report.dart';
export 'native_task_risk_result.dart';
export 'network_capability.dart';
export 'network_speed_sample.dart';
export 'platform_summary.dart';
export 'power_state.dart';
export 'system_feature.dart';
export 'native_lens_debug.dart';
export 'native_lens_screen_trace.dart';
export 'screen_debug_info.dart';
export 'device_orientation_info.dart';

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

  /// Converts the current NativeLens report and compatibility analysis into a
  /// stable dataset row.
  Future<NativeLensDatasetRow> generateDatasetRow() async {
    final NativeLensReport report = await generateReport();
    final CompatibilitySummary compatibilitySummary =
        await analyzeCompatibility();

    return NativeLensDatasetRow(
      schemaVersion: '1.0.0',
      platform: _detectPlatform(report),
      batteryLevel: report.powerState.batteryLevel,
      isCharging: report.powerState.isCharging,
      isPowerSaveMode: report.powerState.isPowerSaveMode,
      networkConnected: report.networkCapability.isConnected,
      networkValidated: report.networkCapability.isValidated,
      networkMetered: report.networkCapability.isMetered,
      hasHevcEncoder: _hasHevcEncoder(report.mediaCodecs),
      maxRefreshRate: _maxRefreshRate(report.displayInfo),
      cameraCount: report.cameraCapabilities.length,
      sensorCount: report.sensors.length,
      codecCount: report.mediaCodecs.length,
      overallScore: compatibilitySummary.overallScore,
      riskLevel: _normalizeRiskLevel(compatibilitySummary.overallLevel),
      labelSource: 'rule_based_v1',
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Analyzes task risk locally using the current NativeLens dataset row.
  ///
  /// This is an offline API skeleton. It does not call a server, Ollama, or an
  /// ML model file. The current rule engine evaluates task-specific device,
  /// power, network, camera, media, and score signals.
  Future<NativeTaskRiskResult> analyzeTaskRisk({
    required NativeLensTask task,
  }) async {
    final NativeLensDatasetRow row = await generateDatasetRow();
    final _TaskRiskSignals signals = _evaluateTaskRiskSignals(task, row);
    final String riskLevel = _riskLevelForSignals(signals);

    return NativeTaskRiskResult(
      task: task,
      riskLevel: riskLevel,
      confidence: _confidenceForSignals(riskLevel, signals),
      reasons: signals.reasons,
      recommendation: _taskRiskRecommendation(task, riskLevel, row),
      analyzedAtMillis: DateTime.now().millisecondsSinceEpoch,
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

  /// Returns the current device orientation snapshot.
  Future<DeviceOrientationInfo> getDeviceOrientation() {
    return NativeLensPlatform.instance.getDeviceOrientation();
  }

  /// Emits orientation updates as the device rotates.
  Stream<DeviceOrientationInfo> get deviceOrientationStream {
    return NativeLensPlatform.instance.deviceOrientationStream;
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

  bool _hasHevcEncoder(List<MediaCodecCapability> codecs) {
    return codecs.any((MediaCodecCapability codec) {
      final List<String> supportedTypes = <String>[...codec.supportedTypes];
      if (codec.supportedVideoTypes.isNotEmpty) {
        supportedTypes.addAll(codec.supportedVideoTypes);
      }

      return supportedTypes.any((String supportedType) {
        final String normalizedType = supportedType.toLowerCase();
        return normalizedType.contains('hevc') ||
            normalizedType.contains('h265');
      });
    });
  }

  double _maxRefreshRate(DisplayInfo displayInfo) {
    if (displayInfo.refreshRate > 0) {
      return displayInfo.refreshRate;
    }

    if (displayInfo.supportedRefreshRates.isNotEmpty) {
      return displayInfo.supportedRefreshRates.reduce(
        (double a, double b) => a > b ? a : b,
      );
    }

    return 0;
  }

  String _detectPlatform(NativeLensReport report) {
    final String operatingSystem = Platform.operatingSystem;
    if (operatingSystem == 'android') {
      return 'android';
    }

    if (operatingSystem == 'ios') {
      return 'ios';
    }

    if (report.platformSummary.androidSdk > 0) {
      return 'android';
    }

    return 'ios';
  }

  String _normalizeRiskLevel(String overallLevel) {
    final String normalizedLevel = overallLevel.toLowerCase();

    if (normalizedLevel == 'excellent' || normalizedLevel == 'good') {
      return 'low';
    }

    if (normalizedLevel == 'fair') {
      return 'medium';
    }

    if (normalizedLevel == 'limited') {
      return 'high';
    }

    return 'unknown';
  }

  _TaskRiskSignals _evaluateTaskRiskSignals(
    NativeLensTask task,
    NativeLensDatasetRow row,
  ) {
    final _TaskRiskSignals signals = _TaskRiskSignals();

    if (row.overallScore < 50) {
      signals.addHigh('Overall compatibility score is below 50.', weight: 4);
    } else if (row.overallScore < 80) {
      signals.addMedium('Overall compatibility score is below 80.', weight: 2);
    }

    switch (task) {
      case NativeLensTask.videoUpload:
        _evaluateUploadNetworkRisk(row, signals);
        _evaluateBatteryRisk(row, signals, highBelow: 10, mediumBelow: 20);
      case NativeLensTask.videoRecording:
        _evaluateBatteryRisk(row, signals, highBelow: 10, mediumBelow: 20);
        _evaluatePowerSaveRisk(row, signals);
        if (row.cameraCount == 0) {
          signals.addHigh('No camera capability was reported.', weight: 4);
        }
        _evaluateSensorCapabilityRisk(row, signals);
        _evaluateRefreshRateRisk(row, signals);
        _evaluateVideoMediaRisk(row, signals);
      case NativeLensTask.audioRecording:
        _evaluateBatteryRisk(row, signals, highBelow: 5, mediumBelow: 10);
        _evaluatePowerSaveRisk(row, signals);
      case NativeLensTask.mediaProcessing:
        _evaluateBatteryRisk(row, signals, highBelow: 15, mediumBelow: 25);
        _evaluatePowerSaveRisk(row, signals);
        _evaluateVideoMediaRisk(row, signals);
      case NativeLensTask.backgroundSync:
        _evaluateUploadNetworkRisk(row, signals);
        _evaluateBatteryRisk(row, signals, highBelow: 10, mediumBelow: 20);
        _evaluatePowerSaveRisk(row, signals);
      case NativeLensTask.cameraCapture:
        if (row.cameraCount == 0) {
          signals.addHigh('No camera capability was reported.', weight: 4);
        }
        _evaluateSensorCapabilityRisk(row, signals);
        _evaluateBatteryRisk(row, signals, highBelow: 5, mediumBelow: 10);
        _evaluatePowerSaveRisk(row, signals);
      case NativeLensTask.realtimeStreaming:
        if (!row.networkConnected) {
          signals.addHigh('Network is not connected.', weight: 4);
        }
        if (!row.networkValidated) {
          signals.addHigh(
            'Network is not validated for internet access.',
            weight: 4,
          );
        }
        if (row.networkMetered) {
          signals.addMedium(
            'Network is metered, which may affect upload or streaming tasks.',
            weight: 2,
          );
        }
        _evaluateRefreshRateRisk(row, signals);
        _evaluateBatteryRisk(row, signals, highBelow: 10, mediumBelow: 15);
    }

    if (signals.reasons.isEmpty) {
      signals.addClean(
        'Overall compatibility score is ${row.overallScore}, and no meaningful task-specific risk signals were detected.',
      );
    }

    return signals;
  }

  void _evaluateUploadNetworkRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (!row.networkConnected) {
      signals.addHigh('Network is not connected.', weight: 4);
    }
    if (!row.networkValidated) {
      signals.addMedium(
        'Network is not validated for internet access.',
        weight: 2,
      );
    }
    if (row.networkMetered) {
      signals.addMedium(
        'Network is metered, which may affect upload or streaming tasks.',
        weight: 2,
      );
    }
  }

  void _evaluateBatteryRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals, {
    required int highBelow,
    required int mediumBelow,
  }) {
    if (row.isCharging) {
      return;
    }

    if (row.batteryLevel < highBelow) {
      signals.addHigh(
        'Battery is below $highBelow% and the device is not charging.',
        weight: 4,
      );
      return;
    }

    if (row.batteryLevel < mediumBelow) {
      signals.addMedium(
        'Battery is below $mediumBelow% and the device is not charging.',
        weight: 2,
      );
    }
  }

  void _evaluatePowerSaveRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (row.isPowerSaveMode) {
      signals.addMedium('Power saver mode is enabled.', weight: 2);
    }
  }

  void _evaluateVideoMediaRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (!row.hasHevcEncoder) {
      signals.addMedium(
        'HEVC encoder is not available; use H.264 fallback.',
        weight: 1,
      );
    }
    if (row.codecCount < 5) {
      signals.addMedium(
        'Codec count is low, which may limit media capability.',
        weight: 1,
      );
    }
  }

  void _evaluateSensorCapabilityRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (row.sensorCount == 0) {
      signals.addMedium(
        'No sensors were reported, which may limit capture stability signals.',
        weight: 1,
      );
    }
  }

  void _evaluateRefreshRateRisk(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (row.maxRefreshRate > 0 && row.maxRefreshRate < 30) {
      signals.addMedium(
        'Maximum refresh rate is below 30Hz, which may affect realtime tasks.',
        weight: 1,
      );
    }
  }

  String _riskLevelForSignals(_TaskRiskSignals signals) {
    if (signals.highSignalCount > 0 || signals.score >= 4) {
      return 'high';
    }

    if (signals.mediumSignalCount > 0 || signals.score >= 2) {
      return 'medium';
    }

    return 'low';
  }

  double _confidenceForSignals(String riskLevel, _TaskRiskSignals signals) {
    double confidence;

    if (riskLevel == 'high') {
      confidence =
          0.72 +
          (signals.highSignalCount * 0.10) +
          (signals.mediumSignalCount * 0.04);
    } else if (riskLevel == 'medium') {
      confidence = 0.64 + (signals.mediumSignalCount * 0.06);
    } else {
      confidence = signals.cleanSignalCount > 0 ? 0.86 : 0.80;
    }

    return confidence.clamp(0.0, 0.95);
  }

  String _taskRiskRecommendation(
    NativeLensTask task,
    String riskLevel,
    NativeLensDatasetRow row,
  ) {
    final String taskLabel = _taskLabel(task);

    if (riskLevel == 'low') {
      return 'Safe to continue $taskLabel under current device conditions.';
    }

    if ((task == NativeLensTask.videoRecording ||
            task == NativeLensTask.mediaProcessing) &&
        !row.hasHevcEncoder) {
      return 'Use H.264 fallback for $taskLabel on this device.';
    }

    switch (task) {
      case NativeLensTask.videoUpload:
        return 'Delay video upload until charging or stable network is available.';
      case NativeLensTask.videoRecording:
        return 'Use lighter video recording settings and monitor battery state.';
      case NativeLensTask.audioRecording:
        return 'Keep audio recording short and monitor battery state.';
      case NativeLensTask.mediaProcessing:
        return 'Use lighter media processing settings until device conditions improve.';
      case NativeLensTask.backgroundSync:
        return 'Delay background sync until network and power conditions improve.';
      case NativeLensTask.cameraCapture:
        return 'Avoid camera capture until camera and power conditions improve.';
      case NativeLensTask.realtimeStreaming:
        return 'Avoid realtime streaming until network becomes connected and validated.';
    }
  }

  String _taskLabel(NativeLensTask task) {
    switch (task) {
      case NativeLensTask.videoUpload:
        return 'Video upload';
      case NativeLensTask.videoRecording:
        return 'Video recording';
      case NativeLensTask.audioRecording:
        return 'Audio recording';
      case NativeLensTask.mediaProcessing:
        return 'Media processing';
      case NativeLensTask.backgroundSync:
        return 'Background sync';
      case NativeLensTask.cameraCapture:
        return 'Camera capture';
      case NativeLensTask.realtimeStreaming:
        return 'Realtime streaming';
    }
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

class _TaskRiskSignals {
  final List<String> reasons = <String>[];
  int score = 0;
  int highSignalCount = 0;
  int mediumSignalCount = 0;
  int cleanSignalCount = 0;

  void addHigh(String reason, {required int weight}) {
    reasons.add(reason);
    score += weight;
    highSignalCount += 1;
  }

  void addMedium(String reason, {required int weight}) {
    reasons.add(reason);
    score += weight;
    mediumSignalCount += 1;
  }

  void addClean(String reason) {
    reasons.add(reason);
    cleanSignalCount += 1;
  }
}
