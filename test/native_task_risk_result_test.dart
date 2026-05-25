import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  group('NativeTaskRiskResult', () {
    const NativeTaskRiskResult result = NativeTaskRiskResult(
      task: NativeLensTask.videoUpload,
      riskLevel: 'low',
      confidence: 0.6,
      reasons: <String>['Overall compatibility score is 90.'],
      recommendation: 'Video upload can proceed.',
      analyzedAtMillis: 1716470400000,
      requiredCapabilities: <String>['stable network'],
      missingCapabilities: <String>[],
      availableCapabilities: <String>['stable network'],
    );

    test('toMap returns stable fields', () {
      expect(result.toMap(), <String, Object>{
        'task': 'videoUpload',
        'riskLevel': 'low',
        'confidence': 0.6,
        'reasons': <String>['Overall compatibility score is 90.'],
        'recommendation': 'Video upload can proceed.',
        'analyzedAtMillis': 1716470400000,
        'requiredCapabilities': <String>['stable network'],
        'missingCapabilities': <String>[],
        'availableCapabilities': <String>['stable network'],
      });
    });

    test('toString returns readable output', () {
      expect(result.toString(), contains('NativeTaskRiskResult'));
      expect(result.toString(), contains('videoUpload'));
      expect(result.toString(), contains('low'));
      expect(result.toString(), contains('requiredCapabilities'));
    });
  });
}
