/// Metadata declared for an HLS master playlist variant stream.
class HlsVariantStream {
  /// Creates HLS variant stream metadata.
  const HlsVariantStream({
    this.uri,
    this.url,
    this.bandwidth,
    this.averageBandwidth,
    this.width,
    this.height,
    this.codecs,
    this.frameRate,
    this.audioGroup,
    this.subtitlesGroup,
    this.closedCaptionsGroup,
    this.name,
  });

  /// Variant URI as declared in the master playlist.
  final String? uri;

  /// Absolute variant URL resolved against the master playlist URL.
  final String? url;

  /// Peak segment bandwidth from the `BANDWIDTH` attribute.
  final int? bandwidth;

  /// Average segment bandwidth from the `AVERAGE-BANDWIDTH` attribute.
  final int? averageBandwidth;

  /// Video width from the `RESOLUTION` attribute.
  final int? width;

  /// Video height from the `RESOLUTION` attribute.
  final int? height;

  /// Codec list from the `CODECS` attribute.
  final String? codecs;

  /// Maximum frame rate from the `FRAME-RATE` attribute.
  final double? frameRate;

  /// Audio rendition group from the `AUDIO` attribute.
  final String? audioGroup;

  /// Subtitles rendition group from the `SUBTITLES` attribute.
  final String? subtitlesGroup;

  /// Closed captions rendition group from the `CLOSED-CAPTIONS` attribute.
  final String? closedCaptionsGroup;

  /// Optional variant name from the `NAME` attribute.
  final String? name;

  /// Creates variant metadata from a map using stable field names.
  factory HlsVariantStream.fromMap(Map<Object?, Object?> map) {
    return HlsVariantStream(
      uri: _readOptionalString(map, 'uri'),
      url: _readOptionalString(map, 'url'),
      bandwidth: _readOptionalInt(map, 'bandwidth'),
      averageBandwidth: _readOptionalInt(map, 'averageBandwidth'),
      width: _readOptionalInt(map, 'width'),
      height: _readOptionalInt(map, 'height'),
      codecs: _readOptionalString(map, 'codecs'),
      frameRate: _readOptionalDouble(map, 'frameRate'),
      audioGroup: _readOptionalString(map, 'audioGroup'),
      subtitlesGroup: _readOptionalString(map, 'subtitlesGroup'),
      closedCaptionsGroup: _readOptionalString(map, 'closedCaptionsGroup'),
      name: _readOptionalString(map, 'name'),
    );
  }

  /// Serializes variant metadata to a map using stable field names.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'uri': uri,
      'url': url,
      'bandwidth': bandwidth,
      'averageBandwidth': averageBandwidth,
      'width': width,
      'height': height,
      'codecs': codecs,
      'frameRate': frameRate,
      'audioGroup': audioGroup,
      'subtitlesGroup': subtitlesGroup,
      'closedCaptionsGroup': closedCaptionsGroup,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'HlsVariantStream('
        'uri: $uri, '
        'url: $url, '
        'bandwidth: $bandwidth, '
        'averageBandwidth: $averageBandwidth, '
        'width: $width, '
        'height: $height, '
        'codecs: $codecs, '
        'frameRate: $frameRate, '
        'audioGroup: $audioGroup, '
        'subtitlesGroup: $subtitlesGroup, '
        'closedCaptionsGroup: $closedCaptionsGroup, '
        'name: $name'
        ')';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
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

  static double? _readOptionalDouble(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
