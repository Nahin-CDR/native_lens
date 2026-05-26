import 'dart:io' show Platform;

import 'camera_capability.dart';
import 'compatibility_summary.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_custom_task_result.dart';
import 'native_lens_dataset_row.dart';
import 'native_lens_platform_interface.dart';
import 'native_lens_report.dart';
import 'native_sensor.dart';
import 'native_task_risk_result.dart';
import 'native_lens_task_requirements.dart';
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
export 'native_lens_custom_task_result.dart';
export 'native_lens_dataset_exporter.dart';
export 'native_lens_dataset_row.dart';
export 'native_lens_task.dart';
export 'native_lens_task_requirements.dart';
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

  /// Emits native battery and power state updates while the platform reports
  /// battery or power state changes.
  Stream<PowerState> watchPowerState() {
    return NativeLensPlatform.instance.watchPowerState();
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
    final List<NativeSensor> sensors = await getSensors();
    final List<SystemFeature> systemFeatures = await getSystemFeatures();
    final _TaskRiskSignals signals = _evaluateTaskRiskSignals(
      task,
      row,
      sensors,
      systemFeatures,
    );
    final String riskLevel = _riskLevelForSignals(signals);

    return NativeTaskRiskResult(
      task: task,
      riskLevel: riskLevel,
      confidence: _confidenceForSignals(riskLevel, signals),
      reasons: signals.reasons,
      recommendation: _taskRiskRecommendation(task, riskLevel, row, signals),
      analyzedAtMillis: DateTime.now().millisecondsSinceEpoch,
      requiredCapabilities: signals.requiredCapabilities,
      missingCapabilities: signals.missingCapabilities,
      availableCapabilities: signals.availableCapabilities,
    );
  }

  /// Analyzes developer-defined task requirements using existing NativeLens
  /// device signals.
  Future<NativeLensCustomTaskResult> analyzeCustomTask({
    required String taskName,
    required NativeLensTaskRequirements requirements,
  }) async {
    final _CustomTaskSignals signals = _CustomTaskSignals();

    if (requirements.requiresCamera) {
      await _evaluateCustomCameraRequirement(signals);
    }

    if (requirements.requiresStableNetwork) {
      await _evaluateCustomStableNetworkRequirement(signals);
    }

    if (requirements.requiresMicrophone ||
        requirements.requiredSystemFeatures.isNotEmpty) {
      final List<SystemFeature> systemFeatures = await getSystemFeatures();

      if (requirements.requiresMicrophone) {
        _evaluateCustomMicrophoneRequirement(systemFeatures, signals);
      }

      for (final String requiredSystemFeature
          in requirements.requiredSystemFeatures) {
        _evaluateCustomSystemFeatureRequirement(
          requiredSystemFeature,
          systemFeatures,
          signals,
        );
      }
    }

    final int? minBatteryLevel = requirements.minBatteryLevel;
    if (minBatteryLevel != null) {
      await _evaluateCustomBatteryRequirement(minBatteryLevel, signals);
    }

    if (requirements.requiredSensors.isNotEmpty) {
      final List<NativeSensor> sensors = await getSensors();
      for (final String requiredSensor in requirements.requiredSensors) {
        _evaluateCustomSensorRequirement(requiredSensor, sensors, signals);
      }
    }

    if (signals.reasons.isEmpty) {
      signals.addAvailableCapability('basic device readiness');
      signals.addInfo('No blocking custom task requirements were detected.');
    }

    final String riskLevel = _customRiskLevelForSignals(signals);
    final String severity = _customSeverityForRiskLevel(riskLevel);

    return NativeLensCustomTaskResult(
      taskName: taskName,
      riskLevel: riskLevel,
      severity: severity,
      canContinue: signals.hardFailureCount == 0,
      requiredCapabilities: signals.requiredCapabilities,
      missingCapabilities: signals.missingCapabilities,
      availableCapabilities: signals.availableCapabilities,
      reasons: signals.reasons,
      recommendations: _customRecommendations(signals, riskLevel),
      userMessage: _customUserMessage(taskName, riskLevel, signals),
      developerMessage: _customDeveloperMessage(taskName, riskLevel, signals),
      analyzedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _evaluateCustomCameraRequirement(
    _CustomTaskSignals signals,
  ) async {
    const String capability = 'camera capability';
    signals.addRequiredCapability(capability);

    final List<CameraCapability> cameras = await getCameraCapabilities();
    if (cameras.isEmpty) {
      signals.addMissingCapability(capability);
      signals.addHardFailure('Camera capability is required but unavailable.');
      return;
    }

    signals.addAvailableCapability(capability);
    signals.addInfo('Camera capability is available.');
  }

  Future<void> _evaluateCustomStableNetworkRequirement(
    _CustomTaskSignals signals,
  ) async {
    const String capability = 'stable network';
    signals.addRequiredCapability(capability);

    final NetworkCapability networkCapability = await getNetworkCapability();
    if (!networkCapability.isConnected) {
      signals.addMissingCapability(capability);
      signals.addHardFailure('Stable network is required but disconnected.');
      return;
    }

    if (!networkCapability.isValidated) {
      signals.addMissingCapability('validated network');
      signals.addHardFailure(
        'Stable network is required but internet access is not validated.',
      );
      return;
    }

    signals.addAvailableCapability(capability);
    signals.addInfo('Stable network is available.');
  }

  void _evaluateCustomMicrophoneRequirement(
    List<SystemFeature> systemFeatures,
    _CustomTaskSignals signals,
  ) {
    const String capability = 'microphone capability';
    signals.addRequiredCapability(capability);

    if (_hasExactSystemFeature(systemFeatures, 'android.hardware.microphone')) {
      signals.addAvailableCapability(capability);
      signals.addInfo('Microphone capability is available.');
      return;
    }

    signals.addMissingCapability(capability);
    signals.addHardFailure(
      'Microphone capability is required but unavailable.',
    );
  }

  void _evaluateCustomSystemFeatureRequirement(
    String requiredSystemFeature,
    List<SystemFeature> systemFeatures,
    _CustomTaskSignals signals,
  ) {
    if (requiredSystemFeature.isEmpty) {
      return;
    }

    signals.addRequiredCapability(requiredSystemFeature);

    if (_hasExactSystemFeature(systemFeatures, requiredSystemFeature)) {
      signals.addAvailableCapability(requiredSystemFeature);
      signals.addInfo('System feature $requiredSystemFeature is available.');
      return;
    }

    signals.addMissingCapability(requiredSystemFeature);
    signals.addHardFailure(
      'System feature $requiredSystemFeature is required but unavailable.',
    );
  }

  Future<void> _evaluateCustomBatteryRequirement(
    int minBatteryLevel,
    _CustomTaskSignals signals,
  ) async {
    final String capability = 'battery level >= $minBatteryLevel%';
    signals.addRequiredCapability(capability);

    final PowerState powerState = await getPowerState();
    if (powerState.batteryLevel < minBatteryLevel) {
      signals.addMissingCapability(capability);
      if (powerState.batteryLevel < 10) {
        signals.addSoftHighRisk(
          'Battery is ${powerState.batteryLevel}%, below the required $minBatteryLevel%.',
        );
      } else {
        signals.addSoftMediumRisk(
          'Battery is ${powerState.batteryLevel}%, below the required $minBatteryLevel%.',
        );
      }
      return;
    }

    signals.addAvailableCapability(capability);
    signals.addInfo(
      'Battery level is ${powerState.batteryLevel}%, meeting the required $minBatteryLevel%.',
    );
  }

  void _evaluateCustomSensorRequirement(
    String requiredSensor,
    List<NativeSensor> sensors,
    _CustomTaskSignals signals,
  ) {
    final _CustomSensorRequirement? sensorRequirement =
        _customSensorRequirementFor(requiredSensor);
    final String capability =
        sensorRequirement?.capability ?? '${requiredSensor.trim()} sensor';

    signals.addRequiredCapability(capability);

    if (sensorRequirement == null) {
      signals.addMissingCapability(capability);
      signals.addHardFailure(
        'Required sensor "$requiredSensor" is not supported by the custom rule engine yet.',
      );
      return;
    }

    if (_hasSensor(
      sensors,
      androidTypes: sensorRequirement.androidTypes,
      nameMatches: sensorRequirement.nameMatches,
    )) {
      signals.addAvailableCapability(capability);
      signals.addInfo('${sensorRequirement.label} is available.');
      return;
    }

    signals.addMissingCapability(capability);
    signals.addHardFailure(
      '${sensorRequirement.label} is required but unavailable.',
    );
  }

  _CustomSensorRequirement? _customSensorRequirementFor(String sensorName) {
    final String normalized = sensorName.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );

    switch (normalized) {
      case 'gyroscope':
      case 'gyro':
        return const _CustomSensorRequirement(
          label: 'Gyroscope sensor',
          capability: 'gyroscope sensor',
          androidTypes: <int>[4, 16],
          nameMatches: <String>['gyroscope', 'gyro'],
        );
      case 'accelerometer':
        return const _CustomSensorRequirement(
          label: 'Accelerometer sensor',
          capability: 'accelerometer sensor',
          androidTypes: <int>[1],
          nameMatches: <String>['accelerometer'],
        );
      case 'magnetometer':
      case 'compass':
        return const _CustomSensorRequirement(
          label: 'Magnetometer or compass sensor',
          capability: 'magnetometer or compass sensor',
          androidTypes: <int>[2],
          nameMatches: <String>['magnetometer', 'magnetic', 'compass'],
        );
      case 'stepcounter':
      case 'stepdetector':
        return const _CustomSensorRequirement(
          label: 'Step counter sensor',
          capability: 'step counter sensor',
          androidTypes: <int>[18, 19],
          nameMatches: <String>['step counter', 'step detector'],
        );
    }

    return null;
  }

  String _customRiskLevelForSignals(_CustomTaskSignals signals) {
    if (signals.hardFailureCount > 0 || signals.softHighRiskCount > 0) {
      return 'high';
    }

    if (signals.softMediumRiskCount > 0) {
      return 'medium';
    }

    return 'low';
  }

  String _customSeverityForRiskLevel(String riskLevel) {
    if (riskLevel == 'high') {
      return 'critical';
    }

    if (riskLevel == 'medium') {
      return 'warning';
    }

    return 'info';
  }

  List<String> _customRecommendations(
    _CustomTaskSignals signals,
    String riskLevel,
  ) {
    if (riskLevel == 'low') {
      return <String>['Continue with the custom task.'];
    }

    final List<String> recommendations = <String>[];
    if (signals.hardFailureCount > 0) {
      recommendations.add(
        'Disable this task or provide a fallback until missing capabilities are available.',
      );
    }

    if (signals.softHighRiskCount > 0 || signals.softMediumRiskCount > 0) {
      recommendations.add(
        'Consider delaying heavy work until battery conditions improve.',
      );
    }

    return recommendations;
  }

  String _customUserMessage(
    String taskName,
    String riskLevel,
    _CustomTaskSignals signals,
  ) {
    if (riskLevel == 'low') {
      return '$taskName looks ready on this device.';
    }

    if (signals.hardFailureCount > 0) {
      return '$taskName cannot continue because required device capabilities are missing.';
    }

    return '$taskName may work, but device conditions are not ideal.';
  }

  String _customDeveloperMessage(
    String taskName,
    String riskLevel,
    _CustomTaskSignals signals,
  ) {
    return 'Custom task "$taskName" analyzed with riskLevel=$riskLevel, '
        'hardFailures=${signals.hardFailureCount}, '
        'softHighRisks=${signals.softHighRiskCount}, '
        'softMediumRisks=${signals.softMediumRiskCount}.';
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
    List<NativeSensor> sensors,
    List<SystemFeature> systemFeatures,
  ) {
    final _TaskRiskSignals signals = _TaskRiskSignals();
    _evaluateCapabilityRequirements(
      task,
      row,
      sensors,
      systemFeatures,
      signals,
    );

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
      case NativeLensTask.arExperience:
        _evaluateBatteryRisk(row, signals, highBelow: 10, mediumBelow: 20);
        _evaluatePowerSaveRisk(row, signals);
      case NativeLensTask.stepTracking:
        _evaluateBatteryRisk(row, signals, highBelow: 5, mediumBelow: 15);
        _evaluatePowerSaveRisk(row, signals);
      case NativeLensTask.compassNavigation:
        _evaluateBatteryRisk(row, signals, highBelow: 5, mediumBelow: 15);
        _evaluatePowerSaveRisk(row, signals);
    }

    if (signals.reasons.isEmpty) {
      signals.addClean(
        'Overall compatibility score is ${row.overallScore}, and no meaningful task-specific risk signals were detected.',
      );
    }

    return signals;
  }

  void _evaluateCapabilityRequirements(
    NativeLensTask task,
    NativeLensDatasetRow row,
    List<NativeSensor> sensors,
    List<SystemFeature> systemFeatures,
    _TaskRiskSignals signals,
  ) {
    switch (task) {
      case NativeLensTask.videoUpload:
        _requireStableNetwork(
          row,
          signals,
          disconnectedReason:
              'Network capability is missing for video upload because the network is not connected.',
          unvalidatedReason: 'Network is not validated for video upload.',
        );
      case NativeLensTask.videoRecording:
        _requireCamera(row, signals);
        _requireMediaCodecs(row, signals);
        _trackHevcAvailability(row, signals);
      case NativeLensTask.audioRecording:
        _trackMicrophoneCapability(systemFeatures, signals);
      case NativeLensTask.mediaProcessing:
        _requireMediaCodecs(row, signals);
        _trackHevcAvailability(row, signals);
      case NativeLensTask.backgroundSync:
        _requireStableNetwork(
          row,
          signals,
          disconnectedReason:
              'Network capability is missing for background sync because the network is not connected.',
          unvalidatedReason: 'Network is not validated for background sync.',
        );
      case NativeLensTask.cameraCapture:
        _requireCamera(row, signals);
      case NativeLensTask.realtimeStreaming:
        _requireStableNetwork(
          row,
          signals,
          disconnectedReason:
              'Network capability is missing for realtime streaming because the network is not connected.',
          unvalidatedReason: 'Network is not validated for realtime streaming.',
          validationIsHighRisk: true,
        );
        if (row.networkMetered) {
          signals.addMissingCapability('unmetered network');
          signals.addMedium(
            'Network is metered, which may affect realtime streaming.',
            weight: 2,
          );
        }
      case NativeLensTask.arExperience:
        _requireCamera(row, signals);
        _requireSensor(
          sensors,
          signals,
          capability: 'gyroscope sensor',
          androidTypes: const <int>[4, 16],
          nameMatches: const <String>['gyroscope', 'gyro'],
          missingReason: 'Required gyroscope sensor is missing.',
        );
        _requireSensor(
          sensors,
          signals,
          capability: 'accelerometer sensor',
          androidTypes: const <int>[1],
          nameMatches: const <String>['accelerometer'],
          missingReason: 'Required accelerometer sensor is missing.',
        );
      case NativeLensTask.stepTracking:
        _requireSensor(
          sensors,
          signals,
          capability: 'step counter or step detector sensor',
          androidTypes: const <int>[18, 19],
          nameMatches: const <String>['step counter', 'step detector'],
          missingReason: 'Required step counter sensor is missing.',
        );
      case NativeLensTask.compassNavigation:
        _requireSensor(
          sensors,
          signals,
          capability: 'magnetometer or compass sensor',
          androidTypes: const <int>[2],
          nameMatches: const <String>['magnetometer', 'magnetic', 'compass'],
          missingReason: 'Required magnetometer or compass sensor is missing.',
        );
    }
  }

  void _requireStableNetwork(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals, {
    required String disconnectedReason,
    required String unvalidatedReason,
    bool validationIsHighRisk = false,
  }) {
    signals.addRequiredCapability('stable network');

    if (!row.networkConnected) {
      signals.addMissingCapability('stable network');
      signals.addHigh(disconnectedReason, weight: 4);
      return;
    }

    if (!row.networkValidated) {
      signals.addMissingCapability('validated network');
      if (validationIsHighRisk) {
        signals.addHigh(unvalidatedReason, weight: 4);
      } else {
        signals.addMedium(unvalidatedReason, weight: 2);
      }
      return;
    }

    signals.addAvailableCapability('stable network');
  }

  void _requireCamera(NativeLensDatasetRow row, _TaskRiskSignals signals) {
    signals.addRequiredCapability('camera capability');

    if (row.cameraCount == 0) {
      signals.addMissingCapability('camera capability');
      signals.addHigh('Camera capability is not available.', weight: 4);
      return;
    }

    signals.addAvailableCapability('camera capability');
  }

  void _requireMediaCodecs(NativeLensDatasetRow row, _TaskRiskSignals signals) {
    signals.addRequiredCapability('media codec capability');

    if (row.codecCount == 0) {
      signals.addMissingCapability('media codec capability');
      signals.addHigh('Media codec capability is not available.', weight: 4);
      return;
    }

    signals.addAvailableCapability('media codec capability');

    if (row.codecCount < 5) {
      signals.addMissingCapability('broad media codec capability');
      signals.addMedium(
        'Media codec capability is limited on this device.',
        weight: 1,
      );
    }
  }

  void _trackHevcAvailability(
    NativeLensDatasetRow row,
    _TaskRiskSignals signals,
  ) {
    if (row.hasHevcEncoder) {
      signals.addAvailableCapability('HEVC encoder');
      return;
    }

    signals.addMissingCapability('HEVC encoder');
  }

  void _trackMicrophoneCapability(
    List<SystemFeature> systemFeatures,
    _TaskRiskSignals signals,
  ) {
    if (_hasSystemFeature(systemFeatures, 'android.hardware.microphone')) {
      signals.addRequiredCapability('microphone capability');
      signals.addAvailableCapability('microphone capability');
      return;
    }

    signals.addClean(
      'Microphone capability was not reported by current system feature data; battery and power conditions were still evaluated.',
    );
  }

  void _requireSensor(
    List<NativeSensor> sensors,
    _TaskRiskSignals signals, {
    required String capability,
    required List<int> androidTypes,
    required List<String> nameMatches,
    required String missingReason,
  }) {
    signals.addRequiredCapability(capability);

    if (_hasSensor(
      sensors,
      androidTypes: androidTypes,
      nameMatches: nameMatches,
    )) {
      signals.addAvailableCapability(capability);
      return;
    }

    signals.addMissingCapability(capability);
    signals.addHigh(missingReason, weight: 4);
  }

  bool _hasSensor(
    List<NativeSensor> sensors, {
    required List<int> androidTypes,
    required List<String> nameMatches,
  }) {
    return sensors.any((NativeSensor sensor) {
      if (androidTypes.contains(sensor.type)) {
        return true;
      }

      final String sensorText = '${sensor.name} ${sensor.typeName}'
          .toLowerCase();
      return nameMatches.any((String match) {
        return sensorText.contains(match.toLowerCase());
      });
    });
  }

  bool _hasSystemFeature(
    List<SystemFeature> systemFeatures,
    String featureName,
  ) {
    final String normalizedFeatureName = featureName.toLowerCase();
    return systemFeatures.any((SystemFeature feature) {
      return feature.name.toLowerCase() == normalizedFeatureName;
    });
  }

  bool _hasExactSystemFeature(
    List<SystemFeature> systemFeatures,
    String featureName,
  ) {
    return systemFeatures.any((SystemFeature feature) {
      return feature.name == featureName;
    });
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
    _TaskRiskSignals signals,
  ) {
    final String taskLabel = _taskLabel(task);

    if (riskLevel == 'low') {
      return 'Safe to continue $taskLabel under current device conditions.';
    }

    if (task == NativeLensTask.arExperience &&
        signals.missingCapabilities.isNotEmpty) {
      return 'Disable AR mode and provide a non-AR fallback experience.';
    }

    if (task == NativeLensTask.stepTracking &&
        signals.missingCapabilities.isNotEmpty) {
      return 'Disable automatic step tracking or use a manual fallback.';
    }

    if (task == NativeLensTask.compassNavigation &&
        signals.missingCapabilities.isNotEmpty) {
      return 'Disable compass navigation or show a map-only fallback.';
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
      case NativeLensTask.arExperience:
        return 'Use a non-AR fallback until required sensors are available.';
      case NativeLensTask.stepTracking:
        return 'Use manual activity entry until step tracking sensors are available.';
      case NativeLensTask.compassNavigation:
        return 'Use map-only navigation until compass sensors are available.';
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
      case NativeLensTask.arExperience:
        return 'AR experience';
      case NativeLensTask.stepTracking:
        return 'Step tracking';
      case NativeLensTask.compassNavigation:
        return 'Compass navigation';
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
  final List<String> requiredCapabilities = <String>[];
  final List<String> missingCapabilities = <String>[];
  final List<String> availableCapabilities = <String>[];
  int score = 0;
  int highSignalCount = 0;
  int mediumSignalCount = 0;
  int cleanSignalCount = 0;

  void addHigh(String reason, {required int weight}) {
    _addUnique(reasons, reason);
    score += weight;
    highSignalCount += 1;
  }

  void addMedium(String reason, {required int weight}) {
    _addUnique(reasons, reason);
    score += weight;
    mediumSignalCount += 1;
  }

  void addClean(String reason) {
    _addUnique(reasons, reason);
    cleanSignalCount += 1;
  }

  void addRequiredCapability(String capability) {
    _addUnique(requiredCapabilities, capability);
  }

  void addMissingCapability(String capability) {
    _addUnique(missingCapabilities, capability);
  }

  void addAvailableCapability(String capability) {
    _addUnique(availableCapabilities, capability);
  }

  void _addUnique(List<String> values, String value) {
    if (!values.contains(value)) {
      values.add(value);
    }
  }
}

class _CustomTaskSignals {
  final List<String> reasons = <String>[];
  final List<String> requiredCapabilities = <String>[];
  final List<String> missingCapabilities = <String>[];
  final List<String> availableCapabilities = <String>[];
  int hardFailureCount = 0;
  int softHighRiskCount = 0;
  int softMediumRiskCount = 0;

  void addHardFailure(String reason) {
    _addUnique(reasons, reason);
    hardFailureCount += 1;
  }

  void addSoftHighRisk(String reason) {
    _addUnique(reasons, reason);
    softHighRiskCount += 1;
  }

  void addSoftMediumRisk(String reason) {
    _addUnique(reasons, reason);
    softMediumRiskCount += 1;
  }

  void addInfo(String reason) {
    _addUnique(reasons, reason);
  }

  void addRequiredCapability(String capability) {
    _addUnique(requiredCapabilities, capability);
  }

  void addMissingCapability(String capability) {
    _addUnique(missingCapabilities, capability);
  }

  void addAvailableCapability(String capability) {
    _addUnique(availableCapabilities, capability);
  }

  void _addUnique(List<String> values, String value) {
    if (!values.contains(value)) {
      values.add(value);
    }
  }
}

class _CustomSensorRequirement {
  const _CustomSensorRequirement({
    required this.label,
    required this.capability,
    required this.androidTypes,
    required this.nameMatches,
  });

  final String label;
  final String capability;
  final List<int> androidTypes;
  final List<String> nameMatches;
}
