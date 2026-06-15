/// Diagnostics summarized from a single fetched HLS playlist body.
class HlsPlaylistSummary {
  /// Creates HLS playlist summary metadata.
  HlsPlaylistSummary({
    this.playlistType,
    this.variantCount = 0,
    this.segmentCount = 0,
    this.totalDurationSeconds,
    this.targetDurationSeconds,
    this.mediaSequence,
    this.isLive = false,
    this.isVod = false,
    this.hasEndList = false,
    this.hasEncryption = false,
    this.hasDiscontinuity = false,
    this.hasByteRanges = false,
    this.maxBandwidth,
    this.minBandwidth,
    this.maxResolutionWidth,
    this.maxResolutionHeight,
    List<String> codecSummary = const <String>[],
  }) : codecSummary = List<String>.unmodifiable(codecSummary);

  /// Playlist classification: `master`, `media`, or `unknown`.
  final String? playlistType;

  /// Number of retained master playlist variants.
  final int variantCount;

  /// Number of retained media playlist segments.
  final int segmentCount;

  /// Sum of retained segment durations from `#EXTINF`.
  final double? totalDurationSeconds;

  /// Target duration from `#EXT-X-TARGETDURATION`.
  final double? targetDurationSeconds;

  /// Starting media sequence from `#EXT-X-MEDIA-SEQUENCE`.
  final int? mediaSequence;

  /// Whether a media playlist has no `#EXT-X-ENDLIST` marker.
  final bool isLive;

  /// Whether a media playlist contains `#EXT-X-ENDLIST`.
  final bool isVod;

  /// Whether the playlist contains `#EXT-X-ENDLIST`.
  final bool hasEndList;

  /// Whether an `#EXT-X-KEY` declares a method other than `NONE`.
  final bool hasEncryption;

  /// Whether the playlist contains `#EXT-X-DISCONTINUITY`.
  final bool hasDiscontinuity;

  /// Whether the playlist contains `#EXT-X-BYTERANGE`.
  final bool hasByteRanges;

  /// Highest parsed variant `BANDWIDTH`.
  final int? maxBandwidth;

  /// Lowest parsed variant `BANDWIDTH`.
  final int? minBandwidth;

  /// Highest parsed variant resolution width.
  final int? maxResolutionWidth;

  /// Highest parsed variant resolution height.
  final int? maxResolutionHeight;

  /// Unique codecs parsed from variant `CODECS` attributes.
  final List<String> codecSummary;

  /// Creates summary metadata from a map using stable field names.
  factory HlsPlaylistSummary.fromMap(Map<Object?, Object?> map) {
    return HlsPlaylistSummary(
      playlistType: _readOptionalString(map, 'playlistType'),
      variantCount: _readNonNegativeInt(map, 'variantCount'),
      segmentCount: _readNonNegativeInt(map, 'segmentCount'),
      totalDurationSeconds: _readOptionalNonNegativeDouble(
        map,
        'totalDurationSeconds',
      ),
      targetDurationSeconds: _readOptionalNonNegativeDouble(
        map,
        'targetDurationSeconds',
      ),
      mediaSequence: _readOptionalNonNegativeInt(map, 'mediaSequence'),
      isLive: _readBool(map, 'isLive'),
      isVod: _readBool(map, 'isVod'),
      hasEndList: _readBool(map, 'hasEndList'),
      hasEncryption: _readBool(map, 'hasEncryption'),
      hasDiscontinuity: _readBool(map, 'hasDiscontinuity'),
      hasByteRanges: _readBool(map, 'hasByteRanges'),
      maxBandwidth: _readOptionalNonNegativeInt(map, 'maxBandwidth'),
      minBandwidth: _readOptionalNonNegativeInt(map, 'minBandwidth'),
      maxResolutionWidth: _readOptionalNonNegativeInt(
        map,
        'maxResolutionWidth',
      ),
      maxResolutionHeight: _readOptionalNonNegativeInt(
        map,
        'maxResolutionHeight',
      ),
      codecSummary: _readStringList(map, 'codecSummary'),
    );
  }

  /// Serializes summary metadata to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'playlistType': playlistType,
      'variantCount': variantCount,
      'segmentCount': segmentCount,
      'totalDurationSeconds': totalDurationSeconds,
      'targetDurationSeconds': targetDurationSeconds,
      'mediaSequence': mediaSequence,
      'isLive': isLive,
      'isVod': isVod,
      'hasEndList': hasEndList,
      'hasEncryption': hasEncryption,
      'hasDiscontinuity': hasDiscontinuity,
      'hasByteRanges': hasByteRanges,
      'maxBandwidth': maxBandwidth,
      'minBandwidth': minBandwidth,
      'maxResolutionWidth': maxResolutionWidth,
      'maxResolutionHeight': maxResolutionHeight,
      'codecSummary': codecSummary,
    };
  }

  @override
  String toString() {
    return 'HlsPlaylistSummary('
        'playlistType: $playlistType, '
        'variantCount: $variantCount, '
        'segmentCount: $segmentCount, '
        'totalDurationSeconds: $totalDurationSeconds, '
        'targetDurationSeconds: $targetDurationSeconds, '
        'mediaSequence: $mediaSequence, '
        'isLive: $isLive, '
        'isVod: $isVod, '
        'hasEndList: $hasEndList, '
        'hasEncryption: $hasEncryption, '
        'hasDiscontinuity: $hasDiscontinuity, '
        'hasByteRanges: $hasByteRanges, '
        'maxBandwidth: $maxBandwidth, '
        'minBandwidth: $minBandwidth, '
        'maxResolutionWidth: $maxResolutionWidth, '
        'maxResolutionHeight: $maxResolutionHeight, '
        'codecSummary: $codecSummary'
        ')';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  static int _readNonNegativeInt(Map<Object?, Object?> map, String key) {
    return _readOptionalNonNegativeInt(map, key) ?? 0;
  }

  static int? _readOptionalNonNegativeInt(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    return value is int && value >= 0 ? value : null;
  }

  static double? _readOptionalNonNegativeDouble(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    if (value is num) {
      final double parsed = value.toDouble();
      return parsed.isFinite && parsed >= 0 ? parsed : null;
    }
    return null;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is bool ? value : false;
  }

  static List<String> _readStringList(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! List<Object?>) {
      return <String>[];
    }

    return value
        .whereType<String>()
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
