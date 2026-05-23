import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  const NativeLensDatasetRow firstRow = NativeLensDatasetRow(
    schemaVersion: '1.0.0',
    platform: 'android',
    batteryLevel: 88,
    isCharging: true,
    isPowerSaveMode: false,
    networkConnected: true,
    networkValidated: true,
    networkMetered: false,
    hasHevcEncoder: true,
    maxRefreshRate: 120,
    cameraCount: 2,
    sensorCount: 10,
    codecCount: 5,
    overallScore: 91,
    riskLevel: 'low',
    labelSource: 'rule_based_v1',
    createdAtMillis: 1716470400000,
  );

  const NativeLensDatasetRow secondRow = NativeLensDatasetRow(
    schemaVersion: '1.0.0',
    platform: 'ios',
    batteryLevel: 55,
    isCharging: false,
    isPowerSaveMode: true,
    networkConnected: false,
    networkValidated: false,
    networkMetered: true,
    hasHevcEncoder: false,
    maxRefreshRate: 60,
    cameraCount: 1,
    sensorCount: 8,
    codecCount: 3,
    overallScore: 64,
    riskLevel: 'medium',
    labelSource: 'rule_based_v1',
    createdAtMillis: 1716470401000,
  );

  test('toJson exports a single row', () {
    final String json = NativeLensDatasetExporter.toJson(firstRow);
    final Map<String, dynamic> decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], '1.0.0');
    expect(decoded['platform'], 'android');
    expect(decoded['batteryLevel'], 88);
    expect(decoded['riskLevel'], 'low');
  });

  test('toJsonList exports multiple rows', () {
    final String json = NativeLensDatasetExporter.toJsonList(<NativeLensDatasetRow>[firstRow, secondRow]);
    final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;

    expect(decoded.length, 2);
    expect(decoded[0]['platform'], 'android');
    expect(decoded[1]['platform'], 'ios');
  });

  test('toCsv returns the expected header row', () {
    final String csv = NativeLensDatasetExporter.toCsv(<NativeLensDatasetRow>[firstRow]);
    final List<String> lines = const LineSplitter().convert(csv);

    expect(lines.first, equals('schemaVersion,platform,batteryLevel,isCharging,isPowerSaveMode,networkConnected,networkValidated,networkMetered,hasHevcEncoder,maxRefreshRate,cameraCount,sensorCount,codecCount,overallScore,riskLevel,labelSource,createdAtMillis'));
  });

  test('toCsv returns row values in the stable column order', () {
    final String csv = NativeLensDatasetExporter.toCsv(<NativeLensDatasetRow>[firstRow]);
    final List<String> lines = const LineSplitter().convert(csv);

    expect(lines.length, 2);
    expect(lines[1], contains('android'));
    expect(lines[1], contains('88'));
    expect(lines[1], contains('low'));
    expect(lines[1], contains('1716470400000'));
  });

  test('toCsv returns header only for an empty list', () {
    final String csv = NativeLensDatasetExporter.toCsv(<NativeLensDatasetRow>[]);
    final List<String> lines = const LineSplitter().convert(csv);

    expect(lines.length, 1);
    expect(lines.first, equals('schemaVersion,platform,batteryLevel,isCharging,isPowerSaveMode,networkConnected,networkValidated,networkMetered,hasHevcEncoder,maxRefreshRate,cameraCount,sensorCount,codecCount,overallScore,riskLevel,labelSource,createdAtMillis'));
  });
}
