import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

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
}
