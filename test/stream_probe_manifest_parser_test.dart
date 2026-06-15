import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/src/stream_probe_manifest_parser.dart';

void main() {
  final Uri baseUri = Uri.parse('https://cdn.example.com/live/master.m3u8');

  test('parses master playlist variants', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,AVERAGE-BANDWIDTH=700000,RESOLUTION=640x360,CODECS="avc1.4d401e,mp4a.40.2",FRAME-RATE=29.970,AUDIO="audio-main",SUBTITLES="subs-main",CLOSED-CAPTIONS="cc-main",NAME="360p"
360p/prog_index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=1280x720
https://media.example.com/720p/prog_index.m3u8
''',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hlsPlaylistType, 'master');
    expect(result.hasVariantStreams, isTrue);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, <String>[
      'https://cdn.example.com/live/360p/prog_index.m3u8',
      'https://media.example.com/720p/prog_index.m3u8',
    ]);
    expect(result.hlsVariants, hasLength(2));
    expect(result.hlsVariants.first.uri, '360p/prog_index.m3u8');
    expect(
      result.hlsVariants.first.url,
      'https://cdn.example.com/live/360p/prog_index.m3u8',
    );
    expect(result.hlsVariants.first.bandwidth, 800000);
    expect(result.hlsVariants.first.averageBandwidth, 700000);
    expect(result.hlsVariants.first.width, 640);
    expect(result.hlsVariants.first.height, 360);
    expect(result.hlsVariants.first.codecs, 'avc1.4d401e,mp4a.40.2');
    expect(result.hlsVariants.first.frameRate, 29.97);
    expect(result.hlsVariants.first.audioGroup, 'audio-main');
    expect(result.hlsVariants.first.subtitlesGroup, 'subs-main');
    expect(result.hlsVariants.first.closedCaptionsGroup, 'cc-main');
    expect(result.hlsVariants.first.name, '360p');
    expect(
      result.hlsVariants.last.url,
      'https://media.example.com/720p/prog_index.m3u8',
    );
    expect(result.hlsVariants.last.bandwidth, 1400000);
    expect(result.hlsVariants.last.width, 1280);
    expect(result.hlsVariants.last.height, 720);
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
    expect(result.hlsPlaylistType, 'media');
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isTrue);
    expect(result.variantUrls, isEmpty);
    expect(result.hlsVariants, isEmpty);
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
    expect(result.hlsVariants.single.uri, '../360p/index.m3u8');
    expect(
      result.hlsVariants.single.url,
      'https://cdn.example.com/live/360p/index.m3u8',
    );
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
    expect(result.hlsPlaylistType, isNull);
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, isEmpty);
    expect(result.hlsVariants, isEmpty);
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
    expect(result.hlsPlaylistType, isNull);
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, isEmpty);
    expect(result.hlsVariants, isEmpty);
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
    expect(result.hlsVariants, hasLength(1));
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
    expect(result.hlsPlaylistType, 'unknown');
    expect(result.hasMediaSegments, isTrue);
    expect(result.segmentUrls, <String>[
      'https://cdn.example.com/live/720p/segment-001.ts',
      'https://cdn.example.com/live/720p/caption-001.vtt',
    ]);
  });

  test('classifies marker-free HLS playlist as unknown', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-VERSION:3
''',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hlsPlaylistType, 'unknown');
    expect(result.hasVariantStreams, isFalse);
    expect(result.hasMediaSegments, isFalse);
  });

  test('does not classify HLS markers without the playlist header', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
''',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.isLikelyHls, isTrue);
    expect(result.hlsPlaylistType, isNull);
    expect(result.hlsVariants, isEmpty);
  });

  test('keeps partial metadata and skips unsafe variant URLs', () {
    final StreamProbeManifestParseResult result = parseStreamProbeManifest(
      manifestBody: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=fast,AVERAGE-BANDWIDTH=-1,RESOLUTION=bad,CODECS="avc1.4d401e,mp4a.40.2",FRAME-RATE=fast,AUDIO="audio"
valid/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1200000
http://[invalid
#EXT-X-STREAM-INF
partial/index.m3u8
''',
      baseUri: baseUri,
      extractVariantLimit: 10,
      extractSegmentLimit: 5,
    );

    expect(result.hlsVariants, hasLength(2));
    expect(result.hlsVariants.first.bandwidth, isNull);
    expect(result.hlsVariants.first.averageBandwidth, isNull);
    expect(result.hlsVariants.first.width, isNull);
    expect(result.hlsVariants.first.height, isNull);
    expect(result.hlsVariants.first.codecs, 'avc1.4d401e,mp4a.40.2');
    expect(result.hlsVariants.first.frameRate, isNull);
    expect(result.hlsVariants.first.audioGroup, 'audio');
    expect(result.hlsVariants.last.uri, 'partial/index.m3u8');
    expect(result.hlsVariants.last.bandwidth, isNull);
    expect(result.variantUrls, <String>[
      'https://cdn.example.com/live/valid/index.m3u8',
      'https://cdn.example.com/live/partial/index.m3u8',
    ]);
  });
}
