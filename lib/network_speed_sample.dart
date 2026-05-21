/// A live app-level network speed sample.
///
/// This measures this app's own Android UID traffic, not full device internet
/// speed and not device-wide network usage.
class NetworkSpeedSample {
  /// Creates a network speed sample.
  const NetworkSpeedSample({
    required this.timestampMillis,
    required this.rxBytesPerSecond,
    required this.txBytesPerSecond,
    required this.rxKbps,
    required this.txKbps,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.isSupported,
  });

  /// The sample time in milliseconds since epoch.
  final int timestampMillis;

  /// Received bytes per second for this app.
  final int rxBytesPerSecond;

  /// Transmitted bytes per second for this app.
  final int txBytesPerSecond;

  /// Received kilobits per second for this app.
  final double rxKbps;

  /// Transmitted kilobits per second for this app.
  final double txKbps;

  /// Total received bytes for this app UID.
  final int totalRxBytes;

  /// Total transmitted bytes for this app UID.
  final int totalTxBytes;

  /// Whether Android supports UID traffic stats on this device.
  final bool isSupported;

  /// Creates a [NetworkSpeedSample] from a map returned by the native platform.
  factory NetworkSpeedSample.fromMap(Map<Object?, Object?> map) {
    return NetworkSpeedSample(
      timestampMillis: _readInt(map, 'timestampMillis'),
      rxBytesPerSecond: _readInt(map, 'rxBytesPerSecond'),
      txBytesPerSecond: _readInt(map, 'txBytesPerSecond'),
      rxKbps: _readDouble(map, 'rxKbps'),
      txKbps: _readDouble(map, 'txKbps'),
      totalRxBytes: _readInt(map, 'totalRxBytes'),
      totalTxBytes: _readInt(map, 'totalTxBytes'),
      isSupported: _readBool(map, 'isSupported'),
    );
  }

  /// Converts this speed sample to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'timestampMillis': timestampMillis,
      'rxBytesPerSecond': rxBytesPerSecond,
      'txBytesPerSecond': txBytesPerSecond,
      'rxKbps': rxKbps,
      'txKbps': txKbps,
      'totalRxBytes': totalRxBytes,
      'totalTxBytes': totalTxBytes,
      'isSupported': isSupported,
    };
  }

  /// Returns a readable string containing all speed sample fields.
  @override
  String toString() {
    return 'NetworkSpeedSample('
        'timestampMillis: $timestampMillis, '
        'rxBytesPerSecond: $rxBytesPerSecond, '
        'txBytesPerSecond: $txBytesPerSecond, '
        'rxKbps: $rxKbps, '
        'txKbps: $txKbps, '
        'totalRxBytes: $totalRxBytes, '
        'totalTxBytes: $totalTxBytes, '
        'isSupported: $isSupported'
        ')';
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static double _readDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }
}
