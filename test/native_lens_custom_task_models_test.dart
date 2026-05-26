import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  group('NativeLensTaskRequirements', () {
    test('defaults are stable', () {
      const NativeLensTaskRequirements requirements =
          NativeLensTaskRequirements();

      expect(requirements.requiresCamera, isFalse);
      expect(requirements.requiresMicrophone, isFalse);
      expect(requirements.requiresStableNetwork, isFalse);
      expect(requirements.requiresUnmeteredNetwork, isFalse);
      expect(requirements.requiresHevcEncoder, isFalse);
      expect(requirements.requiresMediaCodecs, isFalse);
      expect(requirements.requiredSensors, isEmpty);
      expect(requirements.requiredSystemFeatures, isEmpty);
      expect(requirements.minBatteryLevel, isNull);
      expect(requirements.minRefreshRate, isNull);
      expect(requirements.minCameraCount, isNull);
      expect(requirements.minSensorCount, isNull);
      expect(requirements.minCodecCount, isNull);
      expect(requirements.allowPowerSaveMode, isTrue);
    });

    test('toMap returns stable fields', () {
      const NativeLensTaskRequirements requirements =
          NativeLensTaskRequirements(
            requiresCamera: true,
            requiresMicrophone: true,
            requiresStableNetwork: true,
            requiresUnmeteredNetwork: true,
            requiresHevcEncoder: true,
            requiresMediaCodecs: true,
            requiredSensors: <String>['gyroscope', 'accelerometer'],
            requiredSystemFeatures: <String>['android.hardware.camera'],
            minBatteryLevel: 20,
            minRefreshRate: 60,
            minCameraCount: 1,
            minSensorCount: 2,
            minCodecCount: 5,
            allowPowerSaveMode: false,
          );

      expect(requirements.toMap(), <String, Object?>{
        'requiresCamera': true,
        'requiresMicrophone': true,
        'requiresStableNetwork': true,
        'requiresUnmeteredNetwork': true,
        'requiresHevcEncoder': true,
        'requiresMediaCodecs': true,
        'requiredSensors': <String>['gyroscope', 'accelerometer'],
        'requiredSystemFeatures': <String>['android.hardware.camera'],
        'minBatteryLevel': 20,
        'minRefreshRate': 60,
        'minCameraCount': 1,
        'minSensorCount': 2,
        'minCodecCount': 5,
        'allowPowerSaveMode': false,
      });
    });

    test('fromMap reads stable fields', () {
      final NativeLensTaskRequirements requirements =
          NativeLensTaskRequirements.fromMap(<Object?, Object?>{
            'requiresCamera': true,
            'requiresStableNetwork': true,
            'requiredSensors': <Object?>['gyroscope'],
            'minBatteryLevel': 20,
            'minRefreshRate': 90,
            'allowPowerSaveMode': false,
          });

      expect(requirements.requiresCamera, isTrue);
      expect(requirements.requiresStableNetwork, isTrue);
      expect(requirements.requiredSensors, <String>['gyroscope']);
      expect(requirements.minBatteryLevel, 20);
      expect(requirements.minRefreshRate, 90);
      expect(requirements.allowPowerSaveMode, isFalse);
    });
  });

  group('NativeLensCustomTaskResult', () {
    const NativeLensCustomTaskResult result = NativeLensCustomTaskResult(
      taskName: 'Face Filter Camera',
      riskLevel: 'medium',
      severity: 'warning',
      canContinue: true,
      requiredCapabilities: <String>['camera capability'],
      missingCapabilities: <String>['stable network'],
      availableCapabilities: <String>['camera capability'],
      reasons: <String>['Network is not validated.'],
      recommendations: <String>['Retry when network is stable.'],
      userMessage: 'Face Filter Camera may be limited right now.',
      developerMessage: 'Stable network requirement is not met.',
      analyzedAtMillis: 1716470400000,
    );

    test('toMap returns stable fields', () {
      expect(result.toMap(), <String, Object>{
        'taskName': 'Face Filter Camera',
        'riskLevel': 'medium',
        'severity': 'warning',
        'canContinue': true,
        'requiredCapabilities': <String>['camera capability'],
        'missingCapabilities': <String>['stable network'],
        'availableCapabilities': <String>['camera capability'],
        'reasons': <String>['Network is not validated.'],
        'recommendations': <String>['Retry when network is stable.'],
        'userMessage': 'Face Filter Camera may be limited right now.',
        'developerMessage': 'Stable network requirement is not met.',
        'analyzedAtMillis': 1716470400000,
      });
    });

    test('fromMap reads stable fields', () {
      final NativeLensCustomTaskResult decoded =
          NativeLensCustomTaskResult.fromMap(result.toMap());

      expect(decoded.taskName, result.taskName);
      expect(decoded.riskLevel, result.riskLevel);
      expect(decoded.severity, result.severity);
      expect(decoded.canContinue, result.canContinue);
      expect(decoded.requiredCapabilities, result.requiredCapabilities);
      expect(decoded.missingCapabilities, result.missingCapabilities);
      expect(decoded.availableCapabilities, result.availableCapabilities);
      expect(decoded.reasons, result.reasons);
      expect(decoded.recommendations, result.recommendations);
      expect(decoded.userMessage, result.userMessage);
      expect(decoded.developerMessage, result.developerMessage);
      expect(decoded.analyzedAtMillis, result.analyzedAtMillis);
    });

    test('toString contains taskName and riskLevel', () {
      expect(result.toString(), contains('NativeLensCustomTaskResult'));
      expect(result.toString(), contains('Face Filter Camera'));
      expect(result.toString(), contains('medium'));
    });
  });
}
