import '../hls_media_segment.dart';
import '../hls_playlist_summary.dart';
import '../hls_variant_stream.dart';

/// Basic HLS manifest parse result for internal stream URL probing.
class StreamProbeManifestParseResult {
  /// Creates an internal manifest parse result.
  StreamProbeManifestParseResult({
    required this.isLikelyHls,
    required this.hlsPlaylistType,
    required List<String> variantUrls,
    required List<HlsVariantStream> hlsVariants,
    required List<String> segmentUrls,
    required List<HlsMediaSegment> hlsSegments,
    required this.hlsPlaylistSummary,
  }) : variantUrls = List<String>.unmodifiable(variantUrls),
       hlsVariants = List<HlsVariantStream>.unmodifiable(hlsVariants),
       segmentUrls = List<String>.unmodifiable(segmentUrls),
       hlsSegments = List<HlsMediaSegment>.unmodifiable(hlsSegments);

  /// Whether the manifest body appears to be an HLS playlist.
  final bool isLikelyHls;

  /// HLS playlist classification derived from manifest markers.
  final String? hlsPlaylistType;

  /// Diagnostics summarized from the parsed HLS playlist.
  final HlsPlaylistSummary? hlsPlaylistSummary;

  /// Whether variant playlist URLs were found.
  bool get hasVariantStreams => variantUrls.isNotEmpty;

  /// Whether media segment URLs were found.
  bool get hasMediaSegments => segmentUrls.isNotEmpty;

  /// Variant playlist URLs extracted from the manifest.
  final List<String> variantUrls;

  /// Metadata parsed from master playlist variant declarations.
  final List<HlsVariantStream> hlsVariants;

  /// Media segment URLs extracted from the manifest.
  final List<String> segmentUrls;

  /// Metadata parsed from media playlist segment declarations.
  final List<HlsMediaSegment> hlsSegments;
}

/// Parses a basic HLS manifest for readiness signals.
StreamProbeManifestParseResult parseStreamProbeManifest({
  required String manifestBody,
  required Uri baseUri,
  required int extractVariantLimit,
  required int extractSegmentLimit,
}) {
  final List<String> lines = manifestBody
      .split(RegExp(r'\r?\n'))
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList();

  final bool hasExtM3u = lines.any((String line) => line == '#EXTM3U');
  final bool hasMasterMarker = lines.any(
    (String line) => line.startsWith('#EXT-X-STREAM-INF'),
  );
  final bool hasMediaMarker = lines.any(
    (String line) => line.startsWith('#EXTINF'),
  );
  final bool hasHlsMarker = lines.any(_isHlsMarker);
  final List<String> variantUrls = <String>[];
  final List<HlsVariantStream> hlsVariants = <HlsVariantStream>[];
  final List<String> segmentUrls = <String>[];
  final List<HlsMediaSegment> hlsSegments = <HlsMediaSegment>[];
  final bool shouldParseSegmentMetadata =
      hasExtM3u && hasMediaMarker && !hasMasterMarker;
  bool expectVariantUrl = false;
  bool expectSegmentUrl = false;
  Map<String, String>? pendingVariantAttributes;
  double? pendingSegmentDuration;
  String? pendingSegmentTitle;
  String? pendingByteRange;
  bool pendingDiscontinuity = false;
  String? pendingProgramDateTime;
  int? mediaSequence;
  double? targetDurationSeconds;
  int mediaSegmentIndex = 0;
  String? activeKeyMethod;
  String? activeKeyUri;
  bool hasEncryption = false;
  final bool hasEndList = lines.any((String line) => line == '#EXT-X-ENDLIST');
  final bool hasDiscontinuity = lines.any(
    (String line) => line == '#EXT-X-DISCONTINUITY',
  );
  final bool hasByteRanges = lines.any(
    (String line) => line.startsWith('#EXT-X-BYTERANGE'),
  );

  for (final String line in lines) {
    if (line.startsWith('#')) {
      if (line.startsWith('#EXT-X-STREAM-INF')) {
        expectVariantUrl = true;
        pendingVariantAttributes = _parseAttributeList(
          _attributeListFromTag(line),
        );
        expectSegmentUrl = false;
        continue;
      }
      if (expectVariantUrl) {
        expectVariantUrl = false;
        pendingVariantAttributes = null;
      }
      if (line.startsWith('#EXTINF')) {
        expectSegmentUrl = true;
        final (double?, String?) segmentInfo = _parseExtInf(line);
        pendingSegmentDuration = segmentInfo.$1;
        pendingSegmentTitle = segmentInfo.$2;
        continue;
      }
      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE')) {
        mediaSequence = _parseNonNegativeInt(_valueFromTag(line));
        continue;
      }
      if (line.startsWith('#EXT-X-TARGETDURATION')) {
        targetDurationSeconds = _parseNonNegativeDouble(_valueFromTag(line));
        continue;
      }
      if (line.startsWith('#EXT-X-BYTERANGE')) {
        pendingByteRange = _nonEmpty(_valueFromTag(line));
        continue;
      }
      if (line == '#EXT-X-DISCONTINUITY') {
        pendingDiscontinuity = true;
        continue;
      }
      if (line.startsWith('#EXT-X-PROGRAM-DATE-TIME')) {
        pendingProgramDateTime = _nonEmpty(_valueFromTag(line));
        continue;
      }
      if (line.startsWith('#EXT-X-KEY')) {
        final Map<String, String> keyAttributes = _parseAttributeList(
          _attributeListFromTag(line),
        );
        activeKeyMethod = _nonEmpty(keyAttributes['METHOD']);
        if (activeKeyMethod != null &&
            activeKeyMethod.toUpperCase() != 'NONE') {
          hasEncryption = true;
        }
        activeKeyUri =
            activeKeyMethod == null || activeKeyMethod.toUpperCase() == 'NONE'
            ? null
            : _resolveUrl(line: keyAttributes['URI'], baseUri: baseUri);
        continue;
      }
      continue;
    }

    if (expectVariantUrl) {
      final String? resolvedUrl = _addResolvedUrl(
        urls: variantUrls,
        line: line,
        baseUri: baseUri,
        limit: extractVariantLimit,
      );
      if (hasExtM3u && resolvedUrl != null) {
        hlsVariants.add(
          _buildVariant(
            uri: line,
            url: resolvedUrl,
            attributes: pendingVariantAttributes ?? const <String, String>{},
          ),
        );
      }
      expectVariantUrl = false;
      expectSegmentUrl = false;
      pendingVariantAttributes = null;
      continue;
    }

    if (expectSegmentUrl || _looksLikeMediaSegment(line)) {
      final bool isDeclaredSegment = expectSegmentUrl;
      final String? resolvedUrl = _addResolvedUrl(
        urls: segmentUrls,
        line: line,
        baseUri: baseUri,
        limit: extractSegmentLimit,
      );
      if (shouldParseSegmentMetadata &&
          isDeclaredSegment &&
          resolvedUrl != null) {
        hlsSegments.add(
          HlsMediaSegment(
            uri: line,
            url: resolvedUrl,
            durationSeconds: pendingSegmentDuration,
            title: pendingSegmentTitle,
            byteRange: pendingByteRange,
            isDiscontinuity: pendingDiscontinuity,
            programDateTime: pendingProgramDateTime,
            sequenceNumber: mediaSequence == null
                ? null
                : mediaSequence + mediaSegmentIndex,
            keyMethod: activeKeyMethod,
            keyUri: activeKeyUri,
          ),
        );
      }
      if (isDeclaredSegment) {
        mediaSegmentIndex += 1;
      }
      expectSegmentUrl = false;
      pendingSegmentDuration = null;
      pendingSegmentTitle = null;
      pendingByteRange = null;
      pendingDiscontinuity = false;
      pendingProgramDateTime = null;
    }
  }

  final String? hlsPlaylistType = _classifyHlsPlaylist(
    hasExtM3u: hasExtM3u,
    hasMasterMarker: hasMasterMarker,
    hasMediaMarker: hasMediaMarker,
  );

  return StreamProbeManifestParseResult(
    isLikelyHls: hasExtM3u || hasHlsMarker,
    hlsPlaylistType: hlsPlaylistType,
    hlsPlaylistSummary: _buildPlaylistSummary(
      playlistType: hlsPlaylistType,
      variants: hlsVariants,
      segments: hlsSegments,
      targetDurationSeconds: targetDurationSeconds,
      mediaSequence: mediaSequence,
      hasEndList: hasEndList,
      hasEncryption: hasEncryption,
      hasDiscontinuity: hasDiscontinuity,
      hasByteRanges: hasByteRanges,
    ),
    variantUrls: variantUrls,
    hlsVariants: hlsVariants,
    segmentUrls: segmentUrls,
    hlsSegments: hlsSegments,
  );
}

HlsPlaylistSummary? _buildPlaylistSummary({
  required String? playlistType,
  required List<HlsVariantStream> variants,
  required List<HlsMediaSegment> segments,
  required double? targetDurationSeconds,
  required int? mediaSequence,
  required bool hasEndList,
  required bool hasEncryption,
  required bool hasDiscontinuity,
  required bool hasByteRanges,
}) {
  if (playlistType == null) {
    return null;
  }

  final List<int> bandwidths = variants
      .map((HlsVariantStream variant) => variant.bandwidth)
      .whereType<int>()
      .toList(growable: false);
  final List<int> widths = variants
      .map((HlsVariantStream variant) => variant.width)
      .whereType<int>()
      .toList(growable: false);
  final List<int> heights = variants
      .map((HlsVariantStream variant) => variant.height)
      .whereType<int>()
      .toList(growable: false);
  final List<double> durations = segments
      .map((HlsMediaSegment segment) => segment.durationSeconds)
      .whereType<double>()
      .toList(growable: false);
  final Set<String> codecs = <String>{};
  for (final HlsVariantStream variant in variants) {
    for (final String codec in (variant.codecs ?? '').split(',')) {
      final String normalized = codec.trim();
      if (normalized.isNotEmpty) {
        codecs.add(normalized);
      }
    }
  }

  final bool isMediaPlaylist = playlistType == 'media';
  return HlsPlaylistSummary(
    playlistType: playlistType,
    variantCount: variants.length,
    segmentCount: segments.length,
    totalDurationSeconds: durations.isEmpty
        ? null
        : durations.fold<double>(
            0,
            (double total, double duration) => total + duration,
          ),
    targetDurationSeconds: targetDurationSeconds,
    mediaSequence: mediaSequence,
    isLive: isMediaPlaylist && !hasEndList,
    isVod: isMediaPlaylist && hasEndList,
    hasEndList: hasEndList,
    hasEncryption: hasEncryption,
    hasDiscontinuity: hasDiscontinuity,
    hasByteRanges: hasByteRanges,
    maxBandwidth: _maxInt(bandwidths),
    minBandwidth: _minInt(bandwidths),
    maxResolutionWidth: _maxInt(widths),
    maxResolutionHeight: _maxInt(heights),
    codecSummary: codecs.toList(growable: false),
  );
}

int? _maxInt(List<int> values) {
  if (values.isEmpty) {
    return null;
  }
  return values.reduce(
    (int current, int value) => value > current ? value : current,
  );
}

int? _minInt(List<int> values) {
  if (values.isEmpty) {
    return null;
  }
  return values.reduce(
    (int current, int value) => value < current ? value : current,
  );
}

HlsVariantStream _buildVariant({
  required String uri,
  required String url,
  required Map<String, String> attributes,
}) {
  final (int?, int?) resolution = _parseResolution(attributes['RESOLUTION']);
  return HlsVariantStream(
    uri: uri,
    url: url,
    bandwidth: _parseNonNegativeInt(attributes['BANDWIDTH']),
    averageBandwidth: _parseNonNegativeInt(attributes['AVERAGE-BANDWIDTH']),
    width: resolution.$1,
    height: resolution.$2,
    codecs: _nonEmpty(attributes['CODECS']),
    frameRate: _parseNonNegativeDouble(attributes['FRAME-RATE']),
    audioGroup: _nonEmpty(attributes['AUDIO']),
    subtitlesGroup: _nonEmpty(attributes['SUBTITLES']),
    closedCaptionsGroup: _nonEmpty(attributes['CLOSED-CAPTIONS']),
    name: _nonEmpty(attributes['NAME']),
  );
}

String _attributeListFromTag(String line) {
  final int separatorIndex = line.indexOf(':');
  if (separatorIndex < 0 || separatorIndex == line.length - 1) {
    return '';
  }
  return line.substring(separatorIndex + 1);
}

String _valueFromTag(String line) {
  final int separatorIndex = line.indexOf(':');
  if (separatorIndex < 0 || separatorIndex == line.length - 1) {
    return '';
  }
  return line.substring(separatorIndex + 1).trim();
}

(double?, String?) _parseExtInf(String line) {
  final String value = _valueFromTag(line);
  final int separatorIndex = value.indexOf(',');
  final String durationValue = separatorIndex < 0
      ? value
      : value.substring(0, separatorIndex).trim();
  final String titleValue = separatorIndex < 0
      ? ''
      : value.substring(separatorIndex + 1).trim();
  return (_parseNonNegativeDouble(durationValue), _nonEmpty(titleValue));
}

Map<String, String> _parseAttributeList(String input) {
  final Map<String, String> attributes = <String, String>{};
  final StringBuffer token = StringBuffer();
  bool insideQuotes = false;

  void addToken() {
    final String entry = token.toString().trim();
    token.clear();
    if (entry.isEmpty) {
      return;
    }

    final int separatorIndex = entry.indexOf('=');
    if (separatorIndex <= 0) {
      return;
    }

    final String key = entry.substring(0, separatorIndex).trim().toUpperCase();
    String value = entry.substring(separatorIndex + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) {
      attributes[key] = value;
    }
  }

  for (int index = 0; index < input.length; index += 1) {
    final String character = input[index];
    if (character == '"') {
      insideQuotes = !insideQuotes;
      token.write(character);
      continue;
    }
    if (character == ',' && !insideQuotes) {
      addToken();
      continue;
    }
    token.write(character);
  }
  addToken();

  return attributes;
}

(int?, int?) _parseResolution(String? value) {
  final RegExpMatch? match = RegExp(
    r'^(\d+)[xX](\d+)$',
  ).firstMatch(value ?? '');
  if (match == null) {
    return (null, null);
  }

  final int? width = _parsePositiveInt(match.group(1));
  final int? height = _parsePositiveInt(match.group(2));
  if (width == null || height == null) {
    return (null, null);
  }
  return (width, height);
}

int? _parsePositiveInt(String? value) {
  final int? parsed = int.tryParse(value ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

int? _parseNonNegativeInt(String? value) {
  final int? parsed = int.tryParse(value ?? '');
  return parsed != null && parsed >= 0 ? parsed : null;
}

double? _parseNonNegativeDouble(String? value) {
  final double? parsed = double.tryParse(value ?? '');
  return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
}

String? _nonEmpty(String? value) {
  return value == null || value.isEmpty ? null : value;
}

String? _classifyHlsPlaylist({
  required bool hasExtM3u,
  required bool hasMasterMarker,
  required bool hasMediaMarker,
}) {
  if (!hasExtM3u) {
    return null;
  }
  if (hasMasterMarker) {
    return 'master';
  }
  if (hasMediaMarker) {
    return 'media';
  }
  return 'unknown';
}

bool _isHlsMarker(String line) {
  return line.startsWith('#EXT-X-') || line.startsWith('#EXTINF');
}

bool _looksLikeMediaSegment(String line) {
  final String normalized = line.toLowerCase();
  return normalized.contains('.ts') ||
      normalized.contains('.m4s') ||
      normalized.contains('.mp4') ||
      normalized.contains('.aac') ||
      normalized.contains('.vtt');
}

String? _addResolvedUrl({
  required List<String> urls,
  required String line,
  required Uri baseUri,
  required int limit,
}) {
  if (limit <= 0 || urls.length >= limit) {
    return null;
  }

  final String? resolvedUrl = _resolveUrl(line: line, baseUri: baseUri);
  if (resolvedUrl != null) {
    urls.add(resolvedUrl);
  }
  return resolvedUrl;
}

String? _resolveUrl({required String? line, required Uri baseUri}) {
  if (line == null || line.isEmpty) {
    return null;
  }
  try {
    return baseUri.resolve(line).toString();
  } on FormatException {
    return null;
  }
}
