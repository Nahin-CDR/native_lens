import 'dart:convert';

import 'native_lens_dataset_row.dart';

/// Small Dart-only exporter for NativeLens dataset rows.
class NativeLensDatasetExporter {
  static const List<String> _columns = <String>[
    'schemaVersion',
    'platform',
    'batteryLevel',
    'isCharging',
    'isPowerSaveMode',
    'networkConnected',
    'networkValidated',
    'networkMetered',
    'hasHevcEncoder',
    'maxRefreshRate',
    'cameraCount',
    'sensorCount',
    'codecCount',
    'overallScore',
    'riskLevel',
    'labelSource',
    'createdAtMillis',
  ];

  /// Serializes a single row to a JSON string.
  static String toJson(NativeLensDatasetRow row) {
    return jsonEncode(row.toMap());
  }

  /// Serializes a list of rows to a JSON array string.
  static String toJsonList(List<NativeLensDatasetRow> rows) {
    return jsonEncode(rows.map((NativeLensDatasetRow row) => row.toMap()).toList());
  }

  /// Serializes a list of rows to a CSV string.
  static String toCsv(List<NativeLensDatasetRow> rows) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(_columns.join(','));

    for (final NativeLensDatasetRow row in rows) {
      buffer.writeln(_csvLine(row));
    }

    return buffer.toString();
  }

  static String _csvLine(NativeLensDatasetRow row) {
    final Map<String, Object> values = row.toMap();

    return _columns
        .map((String column) => _escapeCsv(values[column].toString()))
        .join(',');
  }

  static String _escapeCsv(String value) {
    final bool needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!needsQuotes) {
      return value;
    }

    final String escapedValue = value.replaceAll('"', '""');
    return '"$escapedValue"';
  }
}
