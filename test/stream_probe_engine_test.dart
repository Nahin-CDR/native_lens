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
#EXT-X-STREAM-INF:BANDWIDTH=800000
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
    expect(result.hasVariantStreams, isTrue);
    expect(result.hasMediaSegments, isFalse);
    expect(result.variantUrls, <String>[
      'https://example.com/live/360p/index.m3u8',
    ]);
    expect(result.probeStage, 'completed');
    expect(result.errorCode, isNull);
    expect(result.elapsedMillis, greaterThanOrEqualTo(0));
    expect(result.manifestByteLength, greaterThan(0));
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
#EXTINF:6.0,
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
    expect(result.finalUrl, 'https://cdn.example.com/live/master.m3u8');
    expect(result.redirectCount, 1);
    expect(client.requestedUrls, <String>[
      'https://example.com/live/master.m3u8',
      'https://cdn.example.com/live/master.m3u8',
    ]);
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
    final NativeLensStreamProbeResult result = await runStreamProbe(
      url: 'https://example.com/index.html',
      options: const NativeLensStreamProbeOptions(),
      httpClient: _FakeStreamProbeHttpClient(<String, Object>{
        'https://example.com/index.html': _response(
          statusCode: 200,
          contentType: 'text/html',
          body: '<html><body>Not a playlist</body></html>',
        ),
      }),
    );

    expect(result.riskLevel, 'medium');
    expect(result.severity, 'warning');
    expect(result.canContinue, isTrue);
    expect(result.isReachable, isTrue);
    expect(result.isManifestReadable, isTrue);
    expect(result.isLikelyHls, isFalse);
    expect(result.errorCode, 'not_hls_manifest');
  });

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
    expect(result.segmentUrls, <String>[
      'https://example.com/live/segment-001.ts',
    ]);
  });
}

StreamProbeHttpResponse _response({
  required int statusCode,
  String? contentType,
  String? body,
  String? location,
}) {
  return StreamProbeHttpResponse(
    statusCode: statusCode,
    bodyBytes: utf8.encode(body ?? ''),
    contentType: contentType,
    location: location,
  );
}

class _FakeStreamProbeHttpClient implements StreamProbeHttpClient {
  _FakeStreamProbeHttpClient(this.responses);

  final Map<String, Object> responses;
  final List<String> requestedUrls = <String>[];

  @override
  Future<StreamProbeHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    requestedUrls.add(uri.toString());
    final Object? response = responses[uri.toString()];
    if (response is TimeoutException) {
      throw response;
    }
    if (response is StreamProbeHttpResponse) {
      return response;
    }
    throw StateError('No fake response for $uri');
  }
}
