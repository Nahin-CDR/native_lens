/// Metadata declared for an HLS media playlist segment.
class HlsMediaSegment {
  /// Creates HLS media segment metadata.
  const HlsMediaSegment({
    this.uri,
    this.url,
    this.durationSeconds,
    this.title,
    this.byteRange,
    this.isDiscontinuity = false,
    this.programDateTime,
    this.sequenceNumber,
    this.keyMethod,
    this.keyUri,
  });

  /// Segment URI as declared in the media playlist.
  final String? uri;

  /// Absolute segment URL resolved against the media playlist URL.
  final String? url;

  /// Segment duration from the `#EXTINF` tag.
  final double? durationSeconds;

  /// Optional segment title from the `#EXTINF` tag.
  final String? title;

  /// Raw byte range from the `#EXT-X-BYTERANGE` tag.
  final String? byteRange;

  /// Whether `#EXT-X-DISCONTINUITY` applies to this segment.
  final bool isDiscontinuity;

  /// Program date-time value from `#EXT-X-PROGRAM-DATE-TIME`.
  final String? programDateTime;

  /// Segment sequence number derived from `#EXT-X-MEDIA-SEQUENCE`.
  final int? sequenceNumber;

  /// Encryption method from the active `#EXT-X-KEY` tag.
  final String? keyMethod;

  /// Absolute key URL resolved from the active `#EXT-X-KEY` URI.
  final String? keyUri;

  /// Creates segment metadata from a map using stable field names.
  factory HlsMediaSegment.fromMap(Map<Object?, Object?> map) {
    return HlsMediaSegment(
      uri: _readOptionalString(map, 'uri'),
      url: _readOptionalString(map, 'url'),
      durationSeconds: _readOptionalDouble(map, 'durationSeconds'),
      title: _readOptionalString(map, 'title'),
      byteRange: _readOptionalString(map, 'byteRange'),
      isDiscontinuity: _readBool(map, 'isDiscontinuity'),
      programDateTime: _readOptionalString(map, 'programDateTime'),
      sequenceNumber: _readOptionalInt(map, 'sequenceNumber'),
      keyMethod: _readOptionalString(map, 'keyMethod'),
      keyUri: _readOptionalString(map, 'keyUri'),
    );
  }

  /// Serializes segment metadata to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uri': uri,
      'url': url,
      'durationSeconds': durationSeconds,
      'title': title,
      'byteRange': byteRange,
      'isDiscontinuity': isDiscontinuity,
      'programDateTime': programDateTime,
      'sequenceNumber': sequenceNumber,
      'keyMethod': keyMethod,
      'keyUri': keyUri,
    };
  }

  @override
  String toString() {
    return 'HlsMediaSegment('
        'uri: $uri, '
        'url: $url, '
        'durationSeconds: $durationSeconds, '
        'title: $title, '
        'byteRange: $byteRange, '
        'isDiscontinuity: $isDiscontinuity, '
        'programDateTime: $programDateTime, '
        'sequenceNumber: $sequenceNumber, '
        'keyMethod: $keyMethod, '
        'keyUri: $keyUri'
        ')';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static double? _readOptionalDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return null;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    return value is bool ? value : false;
  }
}
