import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';
import 'package:native_lens/src/feature_mapping.dart';
import 'package:native_lens/src/preset_task_mapping.dart';

void main() {
  test('NativeLensFeature values exist in stable order', () {
    expect(NativeLensFeature.values, <NativeLensFeature>[
      NativeLensFeature.liveStreaming,
      NativeLensFeature.videoUpload,
      NativeLensFeature.faceFilterCamera,
      NativeLensFeature.cameraRecording,
      NativeLensFeature.backgroundSync,
      NativeLensFeature.arExperience,
      NativeLensFeature.stepTracking,
      NativeLensFeature.compassNavigation,
      NativeLensFeature.mediaProcessing,
    ]);
  });

  group('NativeLensFeatureOptions', () {
    test('defaults are stable', () {
      const NativeLensFeatureOptions options = NativeLensFeatureOptions();

      expect(options.realtime, isFalse);
      expect(options.highPerformance, isFalse);
      expect(options.minBatteryLevel, isNull);
      expect(options.preferUnmeteredNetwork, isFalse);
      expect(options.disallowPowerSaveMode, isFalse);
    });

    test('stores provided values', () {
      const NativeLensFeatureOptions options = NativeLensFeatureOptions(
        realtime: true,
        highPerformance: true,
        minBatteryLevel: 20,
        preferUnmeteredNetwork: true,
        disallowPowerSaveMode: true,
      );

      expect(options.realtime, isTrue);
      expect(options.highPerformance, isTrue);
      expect(options.minBatteryLevel, 20);
      expect(options.preferUnmeteredNetwork, isTrue);
      expect(options.disallowPowerSaveMode, isTrue);
    });
  });

  test('NativeLensFeature display names are stable', () {
    expect(
      <NativeLensFeature, String>{
        for (final NativeLensFeature feature in NativeLensFeature.values)
          feature: nativeLensFeatureDisplayName(feature),
      },
      <NativeLensFeature, String>{
        NativeLensFeature.liveStreaming: 'Live Streaming',
        NativeLensFeature.videoUpload: 'Video Upload',
        NativeLensFeature.faceFilterCamera: 'Face Filter Camera',
        NativeLensFeature.cameraRecording: 'Camera Recording',
        NativeLensFeature.backgroundSync: 'Background Sync',
        NativeLensFeature.arExperience: 'AR Experience',
        NativeLensFeature.stepTracking: 'Step Tracking',
        NativeLensFeature.compassNavigation: 'Compass Navigation',
        NativeLensFeature.mediaProcessing: 'Media Processing',
      },
    );
  });

  test('NativeLensFeature requirement mapping is stable', () {
    expect(
      <NativeLensFeature, Map<String, Object?>>{
        for (final NativeLensFeature feature in NativeLensFeature.values)
          feature: nativeLensFeatureRequirements(feature).toMap(),
      },
      <NativeLensFeature, Map<String, Object?>>{
        NativeLensFeature.liveStreaming: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          requiresMediaCodecs: true,
          requiresHevcEncoder: true,
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensFeature.videoUpload: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          minBatteryLevel: 15,
        ).toMap(),
        NativeLensFeature.faceFilterCamera: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiredSensors: <String>['gyroscope', 'accelerometer'],
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensFeature.cameraRecording: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiresMicrophone: true,
          requiresMediaCodecs: true,
          minBatteryLevel: 15,
        ).toMap(),
        NativeLensFeature.backgroundSync: const NativeLensTaskRequirements(
          requiresStableNetwork: true,
          minBatteryLevel: 15,
          allowPowerSaveMode: false,
        ).toMap(),
        NativeLensFeature.arExperience: const NativeLensTaskRequirements(
          requiresCamera: true,
          requiredSensors: <String>['gyroscope', 'accelerometer'],
          minBatteryLevel: 20,
          minRefreshRate: 60,
        ).toMap(),
        NativeLensFeature.stepTracking: const NativeLensTaskRequirements(
          requiredSensors: <String>['stepCounter'],
        ).toMap(),
        NativeLensFeature.compassNavigation: const NativeLensTaskRequirements(
          requiredSensors: <String>['magnetometer'],
        ).toMap(),
        NativeLensFeature.mediaProcessing: const NativeLensTaskRequirements(
          requiresMediaCodecs: true,
          minBatteryLevel: 20,
          minCodecCount: 1,
        ).toMap(),
      },
    );
  });

  test('NativeLensFeature base mappings match preset mappings', () {
    for (final NativeLensFeature feature in NativeLensFeature.values) {
      final NativeLensPreset preset = _presetForFeature(feature);

      expect(
        nativeLensFeatureDisplayName(feature),
        nativeLensPresetDisplayName(preset),
      );
      expect(
        nativeLensFeatureRequirements(feature).toMap(),
        nativeLensPresetRequirements(preset).toMap(),
      );
    }
  });

  test('NativeLensFeatureOptions apply stricter requirements', () {
    expect(
      nativeLensFeatureRequirements(
        NativeLensFeature.videoUpload,
        options: const NativeLensFeatureOptions(minBatteryLevel: 10),
      ).toMap(),
      const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        minBatteryLevel: 15,
      ).toMap(),
    );

    expect(
      nativeLensFeatureRequirements(
        NativeLensFeature.videoUpload,
        options: const NativeLensFeatureOptions(
          minBatteryLevel: 25,
          preferUnmeteredNetwork: true,
          disallowPowerSaveMode: true,
        ),
      ).toMap(),
      const NativeLensTaskRequirements(
        requiresStableNetwork: true,
        requiresUnmeteredNetwork: true,
        minBatteryLevel: 25,
        allowPowerSaveMode: false,
      ).toMap(),
    );

    expect(
      nativeLensFeatureRequirements(
        NativeLensFeature.cameraRecording,
        options: const NativeLensFeatureOptions(
          realtime: true,
          highPerformance: true,
          minBatteryLevel: 20,
        ),
      ).toMap(),
      const NativeLensTaskRequirements(
        requiresCamera: true,
        requiresMicrophone: true,
        requiresMediaCodecs: true,
        minBatteryLevel: 25,
        minRefreshRate: 60,
      ).toMap(),
    );
  });
}

NativeLensPreset _presetForFeature(NativeLensFeature feature) {
  switch (feature) {
    case NativeLensFeature.liveStreaming:
      return NativeLensPreset.liveStreaming;
    case NativeLensFeature.videoUpload:
      return NativeLensPreset.videoUpload;
    case NativeLensFeature.faceFilterCamera:
      return NativeLensPreset.faceFilterCamera;
    case NativeLensFeature.cameraRecording:
      return NativeLensPreset.cameraRecording;
    case NativeLensFeature.backgroundSync:
      return NativeLensPreset.backgroundSync;
    case NativeLensFeature.arExperience:
      return NativeLensPreset.arExperience;
    case NativeLensFeature.stepTracking:
      return NativeLensPreset.stepTracking;
    case NativeLensFeature.compassNavigation:
      return NativeLensPreset.compassNavigation;
    case NativeLensFeature.mediaProcessing:
      return NativeLensPreset.mediaProcessing;
  }
}
