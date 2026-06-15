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
  }) : variantUrls = List<String>.unmodifiable(variantUrls),
       hlsVariants = List<HlsVariantStream>.unmodifiable(hlsVariants),
       segmentUrls = List<String>.unmodifiable(segmentUrls);

  /// Whether the manifest body appears to be an HLS playlist.
  final bool isLikelyHls;

  /// HLS playlist classification derived from manifest markers.
  final String? hlsPlaylistType;

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
  bool expectVariantUrl = false;
  bool expectSegmentUrl = false;
  Map<String, String>? pendingVariantAttributes;

  for (final String line in lines) {
    if (line.startsWith('#')) {
      expectVariantUrl = line.startsWith('#EXT-X-STREAM-INF');
      pendingVariantAttributes = expectVariantUrl
          ? _parseAttributeList(_attributeListFromTag(line))
          : null;
      expectSegmentUrl = line.startsWith('#EXTINF');
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
      _addResolvedUrl(
        urls: segmentUrls,
        line: line,
        baseUri: baseUri,
        limit: extractSegmentLimit,
      );
      expectSegmentUrl = false;
    }
  }

  return StreamProbeManifestParseResult(
    isLikelyHls: hasExtM3u || hasHlsMarker,
    hlsPlaylistType: _classifyHlsPlaylist(
      hasExtM3u: hasExtM3u,
      hasMasterMarker: hasMasterMarker,
      hasMediaMarker: hasMediaMarker,
    ),
    variantUrls: variantUrls,
    hlsVariants: hlsVariants,
    segmentUrls: segmentUrls,
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

  try {
    final String resolvedUrl = baseUri.resolve(line).toString();
    urls.add(resolvedUrl);
    return resolvedUrl;
  } on FormatException {
    return null;
  }
}
