import '../native_lens_feature.dart';
import '../native_lens_feature_options.dart';
import '../native_lens_task_requirements.dart';

/// Internal display name for a smart feature preflight task.
String nativeLensFeatureDisplayName(NativeLensFeature feature) {
  switch (feature) {
    case NativeLensFeature.liveStreaming:
      return 'Live Streaming';
    case NativeLensFeature.videoUpload:
      return 'Video Upload';
    case NativeLensFeature.faceFilterCamera:
      return 'Face Filter Camera';
    case NativeLensFeature.cameraRecording:
      return 'Camera Recording';
    case NativeLensFeature.backgroundSync:
      return 'Background Sync';
    case NativeLensFeature.arExperience:
      return 'AR Experience';
    case NativeLensFeature.stepTracking:
      return 'Step Tracking';
    case NativeLensFeature.compassNavigation:
      return 'Compass Navigation';
    case NativeLensFeature.mediaProcessing:
      return 'Media Processing';
  }
}

/// Internal requirements mapping for a smart feature preflight task.
NativeLensTaskRequirements nativeLensFeatureRequirements(
  NativeLensFeature feature, {
  NativeLensFeatureOptions options = const NativeLensFeatureOptions(),
}) {
  final NativeLensTaskRequirements baseRequirements = _baseFeatureRequirements(
    feature,
  );

  return _applyFeatureOptions(baseRequirements, options);
}

NativeLensTaskRequirements _baseFeatureRequirements(NativeLensFeature feature) {
  switch (feature) {
    case NativeLensFeature.liveStreaming:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        requiresMediaCodecs: true,
        requiresHevcEncoder: true,
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensFeature.videoUpload:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        minBatteryLevel: 15,
      );
    case NativeLensFeature.faceFilterCamera:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiredSensors: <String>['gyroscope', 'accelerometer'],
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensFeature.cameraRecording:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiresMicrophone: true,
        requiresMediaCodecs: true,
        minBatteryLevel: 15,
      );
    case NativeLensFeature.backgroundSync:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        minBatteryLevel: 15,
        allowPowerSaveMode: false,
      );
    case NativeLensFeature.arExperience:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiredSensors: <String>['gyroscope', 'accelerometer'],
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensFeature.stepTracking:
      return const NativeLensTaskRequirements(
        requiredSensors: <String>['stepCounter'],
      );
    case NativeLensFeature.compassNavigation:
      return const NativeLensTaskRequirements(
        requiredSensors: <String>['magnetometer'],
      );
    case NativeLensFeature.mediaProcessing:
      return const NativeLensTaskRequirements(
        requiresMediaCodecs: true,
        minBatteryLevel: 20,
        minCodecCount: 1,
      );
  }
}

NativeLensTaskRequirements _applyFeatureOptions(
  NativeLensTaskRequirements requirements,
  NativeLensFeatureOptions options,
) {
  final int? minBatteryLevel = _stricterOptionalInt(
    requirements.minBatteryLevel,
    _optionMinBatteryLevel(options),
  );
  final double? minRefreshRate = _stricterOptionalDouble(
    requirements.minRefreshRate,
    _optionMinRefreshRate(options),
  );

  return NativeLensTaskRequirements(
    requiresCamera: requirements.requiresCamera,
    requiresMicrophone: requirements.requiresMicrophone,
    requiresStableNetwork: requirements.requiresStableNetwork,
    requiresUnmeteredNetwork:
        requirements.requiresUnmeteredNetwork || options.preferUnmeteredNetwork,
    requiresHevcEncoder: requirements.requiresHevcEncoder,
    requiresMediaCodecs: requirements.requiresMediaCodecs,
    requiredSensors: requirements.requiredSensors,
    requiredSystemFeatures: requirements.requiredSystemFeatures,
    minBatteryLevel: minBatteryLevel,
    minRefreshRate: minRefreshRate,
    minCameraCount: requirements.minCameraCount,
    minSensorCount: requirements.minSensorCount,
    minCodecCount: requirements.minCodecCount,
    allowPowerSaveMode:
        requirements.allowPowerSaveMode && !options.disallowPowerSaveMode,
  );
}

int? _optionMinBatteryLevel(NativeLensFeatureOptions options) {
  final int? explicitBatteryLevel = options.minBatteryLevel;
  int? minBatteryLevel = explicitBatteryLevel;

  if (options.realtime) {
    minBatteryLevel = _stricterOptionalInt(minBatteryLevel, 20);
  }

  if (options.highPerformance) {
    minBatteryLevel = _stricterOptionalInt(minBatteryLevel, 25);
  }

  return minBatteryLevel;
}

double? _optionMinRefreshRate(NativeLensFeatureOptions options) {
  if (options.realtime || options.highPerformance) {
    return 60;
  }

  return null;
}

int? _stricterOptionalInt(int? currentValue, int? candidateValue) {
  if (currentValue == null) {
    return candidateValue;
  }

  if (candidateValue == null) {
    return currentValue;
  }

  return currentValue > candidateValue ? currentValue : candidateValue;
}

double? _stricterOptionalDouble(double? currentValue, double? candidateValue) {
  if (currentValue == null) {
    return candidateValue;
  }

  if (candidateValue == null) {
    return currentValue;
  }

  return currentValue > candidateValue ? currentValue : candidateValue;
}
