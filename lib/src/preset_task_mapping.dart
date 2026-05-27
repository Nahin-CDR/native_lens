import '../native_lens_preset.dart';
import '../native_lens_task_requirements.dart';

/// Internal display name for a preset feature preflight task.
String nativeLensPresetDisplayName(NativeLensPreset preset) {
  switch (preset) {
    case NativeLensPreset.liveStreaming:
      return 'Live Streaming';
    case NativeLensPreset.videoUpload:
      return 'Video Upload';
    case NativeLensPreset.faceFilterCamera:
      return 'Face Filter Camera';
    case NativeLensPreset.cameraRecording:
      return 'Camera Recording';
    case NativeLensPreset.backgroundSync:
      return 'Background Sync';
    case NativeLensPreset.arExperience:
      return 'AR Experience';
    case NativeLensPreset.stepTracking:
      return 'Step Tracking';
    case NativeLensPreset.compassNavigation:
      return 'Compass Navigation';
    case NativeLensPreset.mediaProcessing:
      return 'Media Processing';
  }
}

/// Internal requirements mapping for a preset feature preflight task.
NativeLensTaskRequirements nativeLensPresetRequirements(
  NativeLensPreset preset,
) {
  switch (preset) {
    case NativeLensPreset.liveStreaming:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        requiresMediaCodecs: true,
        requiresHevcEncoder: true,
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensPreset.videoUpload:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        minBatteryLevel: 15,
      );
    case NativeLensPreset.faceFilterCamera:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiredSensors: <String>['gyroscope', 'accelerometer'],
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensPreset.cameraRecording:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiresMicrophone: true,
        requiresMediaCodecs: true,
        minBatteryLevel: 15,
      );
    case NativeLensPreset.backgroundSync:
      return const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        minBatteryLevel: 15,
        allowPowerSaveMode: false,
      );
    case NativeLensPreset.arExperience:
      return const NativeLensTaskRequirements(
        requiresCamera: true,
        requiredSensors: <String>['gyroscope', 'accelerometer'],
        minBatteryLevel: 20,
        minRefreshRate: 60,
      );
    case NativeLensPreset.stepTracking:
      return const NativeLensTaskRequirements(
        requiredSensors: <String>['stepCounter'],
      );
    case NativeLensPreset.compassNavigation:
      return const NativeLensTaskRequirements(
        requiredSensors: <String>['magnetometer'],
      );
    case NativeLensPreset.mediaProcessing:
      return const NativeLensTaskRequirements(
        requiresMediaCodecs: true,
        minBatteryLevel: 20,
        minCodecCount: 1,
      );
  }
}
