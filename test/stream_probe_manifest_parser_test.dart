import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/src/stream_probe_manifest_parser.dart';

void main() {
  final Uri baseUri = Uri.parse('https://cdn.example.com/live/master.m3u8');

  test('parses master playlist variants', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
360p/prog_index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=1280x720
https://media.example.com/720p/prog_index.m3u8
''',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hasVariantStreams, isTrue);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, <String>[
      'https://cdn.example.com/live/360p/prog_index.m3u8',
      'https://media.example.com/720p/prog_index.m3u8',
    ]);
    expect(result.segmentUrls, isEmpty);
  });

  test('parses media playlist segments', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-TARGETDURATION:6
#EXTINF:6.0,
segment-001.ts
#EXTINF:6.0,
segment-002.ts
''',
      baseUri: Uri.parse('https://cdn.example.com/live/720p/index.m3u8'),
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isTrue);
    expect(result.variantUrls, isEmpty);
    expect(result.segmentUrls, <String>[
      'https://cdn.example.com/live/720p/segment-001.ts',
      'https://cdn.example.com/live/720p/segment-002.ts',
    ]);
  });

  test('resolves relative URLs against base Uri', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
../360p/index.m3u8
#EXTINF:4.0,
segments/segment-001.m4s
''',
      baseUri: Uri.parse('https://cdn.example.com/live/master/index.m3u8'),
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.variantUrls, <String>[
      'https://cdn.example.com/live/360p/index.m3u8',
    ]);
    expect(result.segmentUrls, <String>[
      'https://cdn.example.com/live/master/segments/segment-001.m4s',
    ]);
  });

  test('returns empty signals for empty manifest', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isFalse);
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, isEmpty);
    expect(result.segmentUrls, isEmpty);
  });

  test('returns non-HLS signals for non-HLS body', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '<html><body>Not a playlist</body></html>',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isFalse);
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, isEmpty);
    expect(result.segmentUrls, isEmpty);
  });

  test('applies extraction limits', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000
720p/index.m3u8
#EXTINF:4.0,
segment-001.ts
#EXTINF:4.0,
segment-002.ts
#EXTINF:4.0,
segment-003.ts
''',
      baseUri: baseUri,
      extractVariantLimit: 1,
      extractSegmentLimit: 2,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.variantUrls, <String>[
      'https://cdn.example.com/live/360p/index.m3u8',
    ]);
    expect(result.segmentUrls, <String>[
      'https://cdn.example.com/live/segment-001.ts',
      'https://cdn.example.com/live/segment-002.ts',
    ]);
  });

  test('parses non-comment media segment lines', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
segment-001.ts
caption-001.vtt
not-a-segment.txt
''',
      baseUri: Uri.parse('https://cdn.example.com/live/720p/index.m3u8'),
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hasMediaSegments, isTrue);
    expect(result.segmentUrls, <String>[
      'https://cdn.example.com/live/720p/segment-001.ts',
      'https://cdn.example.com/live/720p/caption-001.vtt',
    ]);
  });
}
