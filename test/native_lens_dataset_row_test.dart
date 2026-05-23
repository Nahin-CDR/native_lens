import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  group('NativeLensDatasetRow', () {
    const NativeLensDatasetRow validRow = NativeLensDatasetRow(
      schemaVersion: 'v1',
      platform: 'android',
      batteryLevel: 72,
      isCharging: true,
      isPowerSaveMode: false,
      networkConnected: true,
      networkValidated: true,
      networkMetered: false,
      hasHevcEncoder: true,
      maxRefreshRate: 120,
      cameraCount: 2,
      sensorCount: 14,
      codecCount: 5,
      overallScore: 91,
      riskLevel: 'low',
      labelSource: 'live-snapshot',
      createdAtMillis: 1716470400000,
    );

    test('toMap returns the expected stable fields', () {
      expect(validRow.toMap(), <String, Object>{
        'schemaVersion': 'v1',
        'platform': 'android',
        'batteryLevel': 72,
        'isCharging': true,
        'isPowerSaveMode': false,
        'networkConnected': true,
        'networkValidated': true,
        'networkMetered': false,
        'hasHevcEncoder': true,
        'maxRefreshRate': 120.0,
        'cameraCount': 2,
        'sensorCount': 14,
        'codecCount': 5,
        'overallScore': 91,
        'riskLevel': 'low',
        'labelSource': 'live-snapshot',
        'createdAtMillis': 1716470400000,
      });
    });

    test('toJson encodes the same values as toMap', () {
      final Map<String, dynamic> decoded = jsonDecode(validRow.toJson()) as Map<String, dynamic>;

      expect(decoded, <String, dynamic>{
        'schemaVersion': 'v1',
        'platform': 'android',
        'batteryLevel': 72,
        'isCharging': true,
        'isPowerSaveMode': false,
        'networkConnected': true,
        'networkValidated': true,
        'networkMetered': false,
        'hasHevcEncoder': true,
        'maxRefreshRate': 120.0,
        'cameraCount': 2,
        'sensorCount': 14,
        'codecCount': 5,
        'overallScore': 91,
        'riskLevel': 'low',
        'labelSource': 'live-snapshot',
        'createdAtMillis': 1716470400000,
      });
    });

    test('isValid returns true for a valid row', () {
      expect(validRow.isValid, isTrue);
    });

    test('isValid returns false for an invalid row', () {
      const NativeLensDatasetRow invalidRow = NativeLensDatasetRow(
        schemaVersion: '',
        platform: 'web',
        batteryLevel: 101,
        isCharging: false,
        isPowerSaveMode: false,
        networkConnected: false,
        networkValidated: false,
        networkMetered: false,
        hasHevcEncoder: false,
        maxRefreshRate: 60,
        cameraCount: 0,
        sensorCount: 0,
        codecCount: 0,
        overallScore: 50,
        riskLevel: 'critical',
        labelSource: '',
        createdAtMillis: 0,
      );

      expect(invalidRow.isValid, isFalse);
    });
  });
}
