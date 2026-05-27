import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';
import 'package:native_lens/src/preset_task_mapping.dart';

void main() {
  test('NativeLensPreset values exist in stable order', () {
    expect(NativeLensPreset.values, <NativeLensPreset>[
      NativeLensPreset.liveStreaming,
      NativeLensPreset.videoUpload,
      NativeLensPreset.faceFilterCamera,
      NativeLensPreset.cameraRecording,
      NativeLensPreset.backgroundSync,
      NativeLensPreset.arExperience,
      NativeLensPreset.stepTracking,
      NativeLensPreset.compassNavigation,
      NativeLensPreset.mediaProcessing,
    ]);
  });

  test('NativeLensTask values remain unchanged', () {
    expect(NativeLensTask.values, <NativeLensTask>[
      NativeLensTask.videoUpload,
      NativeLensTask.videoRecording,
      NativeLensTask.audioRecording,
      NativeLensTask.mediaProcessing,
      NativeLensTask.backgroundSync,
      NativeLensTask.cameraCapture,
      NativeLensTask.realtimeStreaming,
      NativeLensTask.arExperience,
      NativeLensTask.stepTracking,
      NativeLensTask.compassNavigation,
    ]);
  });

  test('NativeLensPreset display names are stable', () {
    expect(
      <NativeLensPreset, String>{
        for (final NativeLensPreset preset in NativeLensPreset.values)
          preset: nativeLensPresetDisplayName(preset),
      },
      <NativeLensPreset, String>{
        NativeLensPreset.liveStreaming: 'Live Streaming',
        NativeLensPreset.videoUpload: 'Video Upload',
        NativeLensPreset.faceFilterCamera: 'Face Filter Camera',
        NativeLensPreset.cameraRecording: 'Camera Recording',
        NativeLensPreset.backgroundSync: 'Background Sync',
        NativeLensPreset.arExperience: 'AR Experience',
        NativeLensPreset.stepTracking: 'Step Tracking',
        NativeLensPreset.compassNavigation: 'Compass Navigation',
        NativeLensPreset.mediaProcessing: 'Media Processing',
      },
    );
  });

  test('NativeLensPreset requirement mapping is stable', () {
    expect(
      <NativeLensPreset, Map<String, Object?>>{
        for (final NativeLensPreset preset in NativeLensPreset.values)
          preset: nativeLensPresetRequirements(preset).toMap(),
      },
      <NativeLensPreset, Map<String, Object?>>{
        NativeLensPreset.liveStreaming: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          requiresMediaCodecs: true,
          requiresHevcEncoder: true,
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensPreset.videoUpload: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          minBatteryLevel: 15,
        ).toMap(),
        NativeLensPreset.faceFilterCamera: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiredSensors: <String>['gyroscope', 'accelerometer'],
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensPreset.cameraRecording: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiresMicrophone: true,
          requiresMediaCodecs: true,
          minBatteryLevel: 15,
        ).toMap(),
        NativeLensPreset.backgroundSync: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          minBatteryLevel: 15,
          allowPowerSaveMode: false,
        ).toMap(),
        NativeLensPreset.arExperience: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiredSensors: <String>['gyroscope', 'accelerometer'],
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensPreset.stepTracking: const NativeLensTaskRequirements(
          requiredSensors: <String>['stepCounter'],
        ).toMap(),
        NativeLensPreset.compassNavigation: const NativeLensTaskRequirements(
          requiredSensors: <String>['magnetometer'],
        ).toMap(),
        NativeLensPreset.mediaProcessing: const NativeLensTaskRequirements(
          requiresMediaCodecs: true,
          minBatteryLevel: 20,
          minCodecCount: 1,
        ).toMap(),
      },
    );
  });
}
