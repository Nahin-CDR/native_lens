/// URL and manifest readiness result for a streaming preflight probe.
class NativeLensStreamProbeResult {
  /// Creates a stream probe result.
  NativeLensStreamProbeResult({
    required this.url,
    required this.finalUrl,
    required this.riskLevel,
    required this.severity,
    required this.canContinue,
    required this.isReachable,
    required this.isManifestReadable,
    required this.isLikelyHls,
    required this.hasVariantStreams,
    required this.hasMediaSegments,
    required List<String> variantUrls,
    required List<String> segmentUrls,
    required List<String> reasons,
    required List<String> recommendations,
    required this.userMessage,
    required this.developerMessage,
    required this.analyzedAtMillis,
    required this.probeStage,
    this.statusCode,
    this.contentType,
    this.redirectCount,
    this.elapsedMillis,
    this.manifestByteLength,
    this.errorCode,
  }) : variantUrls = List<String>.unmodifiable(variantUrls),
       segmentUrls = List<String>.unmodifiable(segmentUrls),
       reasons = List<String>.unmodifiable(reasons),
       recommendations = List<String>.unmodifiable(recommendations);

  /// Original URL requested by the developer.
  final String url;

  /// Final URL after redirects, or the original URL when unchanged.
  final String finalUrl;

  /// Current risk level. Expected values are `low`, `medium`, and `high`.
  final String riskLevel;

  /// User-facing severity. Expected values are `info`, `warning`, and `critical`.
  final String severity;

  /// Whether the app can continue under current probe findings.
  final bool canContinue;

  /// HTTP status code returned by the final probe response, when available.
  final int? statusCode;

  /// Response content type hint, when available.
  final String? contentType;

  /// Whether the URL was reachable over HTTP.
  final bool isReachable;

  /// Whether a manifest body could be read.
  final bool isManifestReadable;

  /// Whether the response appears to be an HLS manifest.
  final bool isLikelyHls;

  /// Whether variant playlist URLs were found.
  final bool hasVariantStreams;

  /// Whether media segment URLs were found.
  final bool hasMediaSegments;

  /// Variant playlist URLs extracted from the manifest.
  final List<String> variantUrls;

  /// Media segment URLs extracted from the manifest.
  final List<String> segmentUrls;

  /// Human-readable reasons for the probe result.
  final List<String> reasons;

  /// Suggested developer or product actions for the probe result.
  final List<String> recommendations;

  /// Short message suitable for showing to an app user.
  final String userMessage;

  /// Diagnostic message suitable for logs or developer tooling.
  final String developerMessage;

  /// Analysis timestamp in milliseconds since epoch.
  final int analyzedAtMillis;

  /// Number of redirects followed during the probe, when available.
  final int? redirectCount;

  /// Probe duration in milliseconds, when available.
  final int? elapsedMillis;

  /// Manifest body length in bytes, when available.
  final int? manifestByteLength;

  /// Current or final stage reached by the probe.
  final String probeStage;

  /// Stable machine-readable error code, when the probe detected an error.
  final String? errorCode;

  /// Creates a stream probe result from a map using stable field names.
  factory NativeLensStreamProbeResult.fromMap(Map<Object?, Object?> map) {
    return NativeLensStreamProbeResult(
      url: _readString(map, 'url'),
      finalUrl: _readString(map, 'finalUrl'),
      riskLevel: _readString(map, 'riskLevel'),
      severity: _readString(map, 'severity'),
      canContinue: _readBool(map, 'canContinue'),
      statusCode: _readOptionalInt(map, 'statusCode'),
      contentType: _readOptionalString(map, 'contentType'),
      isReachable: _readBool(map, 'isReachable'),
      isManifestReadable: _readBool(map, 'isManifestReadable'),
      isLikelyHls: _readBool(map, 'isLikelyHls'),
      hasVariantStreams: _readBool(map, 'hasVariantStreams'),
      hasMediaSegments: _readBool(map, 'hasMediaSegments'),
      variantUrls: _readStringList(map, 'variantUrls'),
      segmentUrls: _readStringList(map, 'segmentUrls'),
      reasons: _readStringList(map, 'reasons'),
      recommendations: _readStringList(map, 'recommendations'),
      userMessage: _readString(map, 'userMessage'),
      developerMessage: _readString(map, 'developerMessage'),
      analyzedAtMillis: _readInt(map, 'analyzedAtMillis'),
      redirectCount: _readOptionalInt(map, 'redirectCount'),
      elapsedMillis: _readOptionalInt(map, 'elapsedMillis'),
      manifestByteLength: _readOptionalInt(map, 'manifestByteLength'),
      probeStage: _readString(map, 'probeStage'),
      errorCode: _readOptionalString(map, 'errorCode'),
    );
  }

  /// Serializes the result to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'url': url,
      'finalUrl': finalUrl,
      'riskLevel': riskLevel,
      'severity': severity,
      'canContinue': canContinue,
      'statusCode': statusCode,
      'contentType': contentType,
      'isReachable': isReachable,
      'isManifestReadable': isManifestReadable,
      'isLikelyHls': isLikelyHls,
      'hasVariantStreams': hasVariantStreams,
      'hasMediaSegments': hasMediaSegments,
      'variantUrls': variantUrls,
      'segmentUrls': segmentUrls,
      'reasons': reasons,
      'recommendations': recommendations,
      'userMessage': userMessage,
      'developerMessage': developerMessage,
      'analyzedAtMillis': analyzedAtMillis,
      'redirectCount': redirectCount,
      'elapsedMillis': elapsedMillis,
      'manifestByteLength': manifestByteLength,
      'probeStage': probeStage,
      'errorCode': errorCode,
    };
  }

  @override
  String toString() {
    return 'NativeLensStreamProbeResult('
        'url: $url, '
        'finalUrl: $finalUrl, '
        'riskLevel: $riskLevel, '
        'severity: $severity, '
        'canContinue: $canContinue, '
        'statusCode: $statusCode, '
        'contentType: $contentType, '
        'isReachable: $isReachable, '
        'isManifestReadable: $isManifestReadable, '
        'isLikelyHls: $isLikelyHls, '
        'hasVariantStreams: $hasVariantStreams, '
        'hasMediaSegments: $hasMediaSegments, '
        'variantUrls: $variantUrls, '
        'segmentUrls: $segmentUrls, '
        'reasons: $reasons, '
        'recommendations: $recommendations, '
        'userMessage: $userMessage, '
        'developerMessage: $developerMessage, '
        'analyzedAtMillis: $analyzedAtMillis, '
        'redirectCount: $redirectCount, '
        'elapsedMillis: $elapsedMillis, '
        'manifestByteLength: $manifestByteLength, '
        'probeStage: $probeStage, '
        'errorCode: $errorCode'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return null;
  }

  static List<String> _readStringList(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! List<Object?>) {
      return <String>[];
    }

    final List<String> values = <String>[];
    for (final Object? item in value) {
      if (item is String && item.isNotEmpty) {
        values.add(item);
      }
    }
    return values;
  }
}
