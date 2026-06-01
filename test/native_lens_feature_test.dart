import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

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
}
