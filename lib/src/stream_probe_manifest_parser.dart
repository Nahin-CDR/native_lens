/// Basic HLS manifest parse result for internal stream URL probing.
class StreamProbeManifestParseResult {
  /// Creates an internal manifest parse result.
  StreamProbeManifestParseResult({
    required this.isLikelyHls,
    required this.hlsPlaylistType,
    required List<String> variantUrls,
    required List<String> segmentUrls,
  }) : variantUrls = List<String>.unmodifiable(variantUrls),
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
  final List<String> segmentUrls = <String>[];
  bool expectVariantUrl = false;
  bool expectSegmentUrl = false;

  for (final String line in lines) {
    if (line.startsWith('#')) {
      expectVariantUrl = line.startsWith('#EXT-X-STREAM-INF');
      expectSegmentUrl = line.startsWith('#EXTINF');
      continue;
    }

    if (expectVariantUrl) {
      _addResolvedUrl(
        urls: variantUrls,
        line: line,
        baseUri: baseUri,
        limit: extractVariantLimit,
      );
      expectVariantUrl = false;
      expectSegmentUrl = false;
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
    segmentUrls: segmentUrls,
  );
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

void _addResolvedUrl({
  required List<String> urls,
  required String line,
  required Uri baseUri,
  required int limit,
}) {
  if (limit <= 0 || urls.length >= limit) {
    return;
  }

  urls.add(baseUri.resolve(line).toString());
}
