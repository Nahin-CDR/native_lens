import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';
import 'package:native_lens/src/stream_probe_engine.dart';

void main() {
  test('returns high risk for invalid URL', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'not a url',
      options: const NativeLensStreamProbeOptions(),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{}),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.probeStage, 'urlValidation');
    expect(result.errorCode, 'invalid_url');
    expect(result.isReachable, isFalse);
  });

  test('returns high risk for unsupported scheme', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'ftp://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{}),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.errorCode, 'unsupported_scheme');
    expect(result.reasons.single, contains('ftp'));
  });

  test('returns high risk when HTTPS is required', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'http://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(requireHttps: true),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{}),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.errorCode, 'https_required');
    expect(result.recommendations.single, contains('HTTPS'));
  });

  test('returns low risk for HTTP 200 valid HLS manifest', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/master.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,AVERAGE-BANDWIDTH=700000,RESOLUTION=640x360,CODECS="avc1.4d401e,mp4a.40.2"
360p/index.m3u8
''',
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(),
      httpClient: client,
    );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.statusCode, 200);
    expect(result.contentType, 'application/vnd.apple.mpegurl');
    expect(result.isReachable, isTrue);
    expect(result.isManifestReadable, isTrue);
    expect(result.isLikelyHls, isTrue);
    expect(result.hlsPlaylistType, 'master');
    expect(result.isMasterPlaylist, isTrue);
    expect(result.isMediaPlaylist, isFalse);
    expect(result.hasVariantStreams, isTrue);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, <String>[
      'https://example.com/live/360p/index.m3u8',
    ]);
    expect(result.hlsVariants, hasLength(1));
    expect(result.hlsVariants.single.bandwidth, 800000);
    expect(result.hlsVariants.single.averageBandwidth, 700000);
    expect(result.hlsVariants.single.width, 640);
    expect(result.hlsVariants.single.height, 360);
    expect(result.hlsVariants.single.codecs, 'avc1.4d401e,mp4a.40.2');
    expect(result.hlsSegments, isEmpty);
    expect(result.hlsPlaylistSummary, isNotNull);
    expect(result.hlsPlaylistSummary!.variantCount, 1);
    expect(result.hlsPlaylistSummary!.maxBandwidth, 800000);
    expect(result.hlsPlaylistSummary!.codecSummary, <String>[
      'avc1.4d401e',
      'mp4a.40.2',
    ]);
    expect(result.probeStage, 'completed');
    expect(result.errorCode, isNull);
    expect(result.elapsedMillis, greaterThanOrEqualTo(0));
    expect(result.manifestByteLength, greaterThan(0));
  });

  test('does not check segments for master playlists when opted in', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/master.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
''',
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
      httpClient: client,
    );

    expect(result.hlsPlaylistType, 'master');
    expect(result.firstSegmentReachability, isNull);
    expect(client.requestedUrls, <String>[
      'https://example.com/live/master.m3u8',
    ]);
    expect(client.requestedMethods, <String>['GET']);
  });

  test('follows redirects using options', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/master.m3u8': _response(
            statusCode: 302,
            location: 'https://cdn.example.com/live/master.m3u8',
          ),
          'https://cdn.example.com/live/master.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '''
#EXTM3U
#EXT-X-MEDIA-SEQUENCE:42
#EXTINF:6.0,Redirected segment
segment-001.ts
''',
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(),
      httpClient: client,
    );

    expect(result.riskLevel, 'low');
    expect(result.hlsPlaylistType, 'media');
    expect(result.hlsVariants, isEmpty);
    expect(result.hlsSegments, hasLength(1));
    expect(result.hlsSegments.single.durationSeconds, 6.0);
    expect(result.hlsSegments.single.title, 'Redirected segment');
    expect(result.hlsSegments.single.sequenceNumber, 42);
    expect(result.hlsPlaylistSummary, isNotNull);
    expect(result.hlsPlaylistSummary!.segmentCount, 1);
    expect(result.hlsPlaylistSummary!.totalDurationSeconds, 6);
    expect(result.hlsPlaylistSummary!.mediaSequence, 42);
    expect(result.hlsPlaylistSummary!.isLive, isTrue);
    expect(result.firstSegmentReachability, isNull);
    expect(result.isMasterPlaylist, isFalse);
    expect(result.isMediaPlaylist, isTrue);
    expect(result.finalUrl, 'https://cdn.example.com/live/master.m3u8');
    expect(result.redirectCount, 1);
    expect(client.requestedUrls, <String>[
      'https://example.com/live/master.m3u8',
      'https://cdn.example.com/live/master.m3u8',
    ]);
    expect(client.requestedMethods, <String>['GET', 'GET']);
  });

  test('checks first media segment with HEAD when opted in', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/index.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '''
#EXTM3U
#EXTINF:6.0,First segment
segment-001.ts
#EXTINF:6.0,Second segment
segment-002.ts
''',
          ),
          'HEAD https://example.com/live/segment-001.ts': _response(
            statusCode: 200,
            contentType: 'video/mp2t',
            contentLength: 75232,
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/index.m3u8',
      options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
      httpClient: client,
    );

    expect(result.riskLevel, 'low');
    expect(result.hlsSegments, hasLength(2));
    expect(result.firstSegmentReachability, isNotNull);
    expect(result.firstSegmentReachability!.checked, isTrue);
    expect(
      result.firstSegmentReachability!.url,
      'https://example.com/live/segment-001.ts',
    );
    expect(result.firstSegmentReachability!.method, 'HEAD');
    expect(result.firstSegmentReachability!.isReachable, isTrue);
    expect(result.firstSegmentReachability!.statusCode, 200);
    expect(result.firstSegmentReachability!.contentType, 'video/mp2t');
    expect(result.firstSegmentReachability!.contentLength, 75232);
    expect(
      result.firstSegmentReachability!.responseTimeMs,
      greaterThanOrEqualTo(0),
    );
    expect(result.firstSegmentReachability!.errorType, isNull);
    expect(client.requestedUrls, <String>[
      'https://example.com/live/index.m3u8',
      'https://example.com/live/segment-001.ts',
    ]);
    expect(client.requestedMethods, <String>['GET', 'HEAD']);
  });

  test(
    'does not fallback when first segment HEAD is method not allowed',
    () async {
      final _FakeStreamProbeHttpClient client =
          _FakeStreamProbeHttpClient(<String, Object>{
            'https://example.com/live/index.m3u8': _response(
              statusCode: 200,
              contentType: 'application/vnd.apple.mpegurl',
              body: '''
#EXTM3U
#EXTINF:6.0,
segment-001.ts
''',
            ),
            'HEAD https://example.com/live/segment-001.ts': _response(
              statusCode: 405,
              contentType: 'text/plain',
            ),
          });

      final NativeLensStreamProbeResult result = await runStreamProbe(
        url: 'https://example.com/live/index.m3u8',
        options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
        httpClient: client,
      );

      expect(result.riskLevel, 'low');
      expect(result.firstSegmentReachability, isNotNull);
      expect(result.firstSegmentReachability!.checked, isTrue);
      expect(result.firstSegmentReachability!.method, 'HEAD');
      expect(result.firstSegmentReachability!.isReachable, isFalse);
      expect(result.firstSegmentReachability!.statusCode, 405);
      expect(result.firstSegmentReachability!.errorType, isNull);
      expect(client.requestedMethods, <String>['GET', 'HEAD']);
    },
  );

  test('records first segment timeout as diagnostics', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/index.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '''
#EXTM3U
#EXTINF:6.0,
segment-001.ts
''',
          ),
          'HEAD https://example.com/live/segment-001.ts': TimeoutException(
            'slow segment',
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/index.m3u8',
      options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
      httpClient: client,
    );

    expect(result.riskLevel, 'low');
    expect(result.errorCode, isNull);
    expect(result.firstSegmentReachability, isNotNull);
    expect(result.firstSegmentReachability!.checked, isTrue);
    expect(result.firstSegmentReachability!.isReachable, isFalse);
    expect(result.firstSegmentReachability!.statusCode, isNull);
    expect(result.firstSegmentReachability!.errorType, 'timeout');
    expect(
      result.firstSegmentReachability!.responseTimeMs,
      greaterThanOrEqualTo(0),
    );
  });

  test('returns high risk for HTTP 404', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/missing.m3u8',
      options: const NativeLensStreamProbeOptions(),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/missing.m3u8': _response(
          statusCode: 404,
          contentType: 'text/plain',
          body: 'Not found',
        ),
      }),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.statusCode, 404);
    expect(result.errorCode, 'http_status');
    expect(result.probeStage, 'httpRequest');
  });

  test('returns high risk for timeout', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/slow.m3u8',
      options: const NativeLensStreamProbeOptions(
        timeout: Duration(milliseconds: 1),
      ),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/slow.m3u8': TimeoutException('slow'),
      }),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.errorCode, 'timeout');
    expect(result.probeStage, 'httpRequest');
  });

  test('returns medium risk for non-HLS body', () async {
    final _FakeStreamProbeHttpClient client =
        _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/index.html': _response(
            statusCode: 200,
            contentType: 'text/html',
            body: '<html><body>Not a playlist</body></html>',
          ),
        });

    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/index.html',
      options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
      httpClient: client,
    );

    expect(result.riskLevel, 'medium');
    expect(result.severity, 'warning');
    expect(result.canContinue, isTrue);
    expect(result.isReachable, isTrue);
    expect(result.isManifestReadable, isTrue);
    expect(result.isLikelyHls, isFalse);
    expect(result.hlsPlaylistType, isNull);
    expect(result.hlsVariants, isEmpty);
    expect(result.hlsSegments, isEmpty);
    expect(result.hlsPlaylistSummary, isNull);
    expect(result.firstSegmentReachability, isNull);
    expect(result.isMasterPlaylist, isFalse);
    expect(result.isMediaPlaylist, isFalse);
    expect(result.errorCode, 'not_hls_manifest');
    expect(client.requestedMethods, <String>['GET']);
  });

  test('classifies marker-free HLS manifest as unknown', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/playlist.m3u8',
      options: const NativeLensStreamProbeOptions(checkFirstHlsSegment: true),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/live/playlist.m3u8': _response(
          statusCode: 200,
          contentType: 'application/vnd.apple.mpegurl',
          body: '''
#EXTM3U
#EXT-X-VERSION:3
''',
        ),
      }),
    );

    expect(result.riskLevel, 'medium');
    expect(result.isLikelyHls, isTrue);
    expect(result.hlsPlaylistType, 'unknown');
    expect(result.hlsVariants, isEmpty);
    expect(result.hlsSegments, isEmpty);
    expect(result.hlsPlaylistSummary, isNotNull);
    expect(result.hlsPlaylistSummary!.playlistType, 'unknown');
    expect(result.firstSegmentReachability, isNull);
    expect(result.isMasterPlaylist, isFalse);
    expect(result.isMediaPlaylist, isFalse);
    expect(result.errorCode, 'empty_hls_manifest');
  });

  test(
    'does not classify non-HLS body from URL and content type hints',
    () async {
      final NativeLensStreamProbeResult result = await runStreamProbe(
        url: 'https://example.com/live/playlist.m3u8',
        options: const NativeLensStreamProbeOptions(),
        httpClient: _FakeStreamProbeHttpClient(<String, Object>{
          'https://example.com/live/playlist.m3u8': _response(
            statusCode: 200,
            contentType: 'application/vnd.apple.mpegurl',
            body: '<html><body>Not a playlist</body></html>',
          ),
        }),
      );

      expect(result.isLikelyHls, isTrue);
      expect(result.hlsPlaylistType, isNull);
      expect(result.hlsVariants, isEmpty);
      expect(result.hlsSegments, isEmpty);
      expect(result.hlsPlaylistSummary, isNull);
      expect(result.firstSegmentReachability, isNull);
      expect(result.isMasterPlaylist, isFalse);
      expect(result.isMediaPlaylist, isFalse);
      expect(result.errorCode, 'empty_hls_manifest');
    },
  );

  test('returns high risk when manifest is too large', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(maxManifestBytes: 4),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/live/master.m3u8': _response(
          statusCode: 200,
          contentType: 'application/vnd.apple.mpegurl',
          body: '#EXTM3U',
        ),
      }),
    );

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.isReachable, isTrue);
    expect(result.isManifestReadable, isFalse);
    expect(result.manifestByteLength, 7);
    expect(result.errorCode, 'manifest_too_large');
    expect(result.probeStage, 'manifestSize');
  });

  test('includes variant and segment extraction result', () async {
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/live/master.m3u8',
      options: const NativeLensStreamProbeOptions(
        extractVariantLimit: 1,
        extractSegmentLimit: 1,
      ),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/live/master.m3u8': _response(
          statusCode: 200,
          contentType: 'application/vnd.apple.mpegurl',
          body: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=1400000
720p/index.m3u8
#EXTINF:6.0,
segment-001.ts
#EXTINF:6.0,
segment-002.ts
''',
        ),
      }),
    );

    expect(result.riskLevel, 'low');
    expect(result.hasVariantStreams, isTrue);
    expect(result.hasMediaSegments, isTrue);
    expect(result.variantUrls, <String>[
      'https://example.com/live/360p/index.m3u8',
    ]);
    expect(result.hlsVariants, hasLength(1));
    expect(result.hlsVariants.single.bandwidth, 800000);
    expect(result.hlsSegments, isEmpty);
    expect(result.segmentUrls, <String>[
      'https://example.com/live/segment-001.ts',
    ]);
  });
}

StreamProbeHttpResponse _response({
  required int statusCode,
  String? contentType,
  int? contentLength,
  String? body,
  String? location,
}) {
  return StreamProbeHttpResponse(
    statusCode: statusCode,
    bodyBytes: utf8.encode(body ?? ''),
    contentType: contentType,
    contentLength: contentLength,
    location: location,
  );
}

class _FakeStreamProbeHttpClient implements StreamProbeHttpClient {
  _FakeStreamProbeHttpClient(this.responses);

  final Map<String, Object> responses;
  final List<String> requestedUrls = <String>[];
  final List<String> requestedMethods = <String>[];

  @override
  Future<StreamProbeHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    return _request('GET', uri);
  }

  @override
  Future<StreamProbeHttpResponse> head(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    return _request('HEAD', uri);
  }

  Future<StreamProbeHttpResponse> _request(String method, Uri uri) async {
    requestedMethods.add(method);
    requestedUrls.add(uri.toString());
    final Object? response =
        responses['$method ${uri.toString()}'] ?? responses[uri.toString()];
    if (response is TimeoutException) {
      throw response;
    }
    if (response is StreamProbeHttpResponse) {
      return response;
    }
    throw StateError('No fake response for $uri');
  }
}
