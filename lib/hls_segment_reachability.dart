/// Reachability diagnostics for one HLS media segment URL.
class HlsSegmentReachability {
  /// Creates HLS segment reachability diagnostics.
  const HlsSegmentReachability({
    this.checked = false,
    this.url,
    this.method,
    this.isReachable = false,
    this.statusCode,
    this.contentType,
    this.contentLength,
    this.responseTimeMs,
    this.errorType,
    this.errorMessage,
  });

  /// Whether a segment reachability request was attempted.
  final bool checked;

  /// Segment URL that was checked.
  final String? url;

  /// HTTP method used for the check.
  final String? method;

  /// Whether the segment responded with a successful HTTP status.
  final bool isReachable;

  /// HTTP status code returned by the segment check.
  final int? statusCode;

  /// Segment response content type, when available.
  final String? contentType;

  /// Segment response content length, when available.
  final int? contentLength;

  /// Segment check response time in milliseconds.
  final int? responseTimeMs;

  /// Stable diagnostic error type, when the check failed before a response.
  final String? errorType;

  /// Human-readable diagnostic error message, when available.
  final String? errorMessage;

  /// Creates reachability diagnostics from a map using stable field names.
  factory HlsSegmentReachability.fromMap(Map<Object?, Object?> map) {
    return HlsSegmentReachability(
      checked: _readBool(map, 'checked'),
      url: _readOptionalString(map, 'url'),
      method: _readOptionalString(map, 'method'),
      isReachable: _readBool(map, 'isReachable'),
      statusCode: _readOptionalInt(map, 'statusCode'),
      contentType: _readOptionalString(map, 'contentType'),
      contentLength: _readOptionalInt(map, 'contentLength'),
      responseTimeMs: _readOptionalInt(map, 'responseTimeMs'),
      errorType: _readOptionalString(map, 'errorType'),
      errorMessage: _readOptionalString(map, 'errorMessage'),
    );
  }

  /// Serializes reachability diagnostics to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'checked': checked,
      'url': url,
      'method': method,
      'isReachable': isReachable,
      'statusCode': statusCode,
      'contentType': contentType,
      'contentLength': contentLength,
      'responseTimeMs': responseTimeMs,
      'errorType': errorType,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'HlsSegmentReachability('
        'checked: $checked, '
        'url: $url, '
        'method: $method, '
        'isReachable: $isReachable, '
        'statusCode: $statusCode, '
        'contentType: $contentType, '
        'contentLength: $contentLength, '
        'responseTimeMs: $responseTimeMs, '
        'errorType: $errorType, '
        'errorMessage: $errorMessage'
        ')';
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is bool ? value : false;
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is int && value >= 0 ? value : null;
  }
}
