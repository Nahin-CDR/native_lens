import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  group('NativeLensStreamProbeOptions', () {
    test('defaults are stable', () {
      const NativeLensStreamProbeOptions options =
          NativeLensStreamProbeOptions();

      expect(options.timeout, const Duration(seconds: 8));
      expect(options.followRedirects, isTrue);
      expect(options.maxRedirects, 5);
      expect(options.maxManifestBytes, 1024 * 1024);
      expect(options.extractSegmentLimit, 5);
      expect(options.extractVariantLimit, 10);
      expect(options.requireHttps, isFalse);
      expect(options.allowedSchemes, <String>['http', 'https']);
      expect(options.headers, isEmpty);
    });

    test('stores custom values', () {
      const NativeLensStreamProbeOptions options = NativeLensStreamProbeOptions(
        timeout: Duration(seconds: 3),
        followRedirects: false,
        maxRedirects: 2,
        maxManifestBytes: 2048,
        extractSegmentLimit: 3,
        extractVariantLimit: 4,
        requireHttps: true,
        allowedSchemes: <String>['https'],
        headers: <String, String>{'Authorization': 'Bearer token'},
      );

      expect(options.timeout, const Duration(seconds: 3));
      expect(options.followRedirects, isFalse);
      expect(options.maxRedirects, 2);
      expect(options.maxManifestBytes, 2048);
      expect(options.extractSegmentLimit, 3);
      expect(options.extractVariantLimit, 4);
      expect(options.requireHttps, isTrue);
      expect(options.allowedSchemes, <String>['https']);
      expect(options.headers, <String, String>{
        'Authorization': 'Bearer token',
      });
    });
  });

  group('NativeLensStreamProbeResult', () {
    final NativeLensStreamProbeResult result = NativeLensStreamProbeResult(
      url: 'https://example.com/live/master.m3u8',
      finalUrl: 'https://cdn.example.com/live/master.m3u8',
      riskLevel: 'low',
      severity: 'info',
      canContinue: true,
      statusCode: 200,
      contentType: 'application/vnd.apple.mpegurl',
      isReachable: true,
      isManifestReadable: true,
      isLikelyHls: true,
      hlsPlaylistType: 'master',
      hasVariantStreams: true,
      hasMediaSegments: false,
      variantUrls: <String>['https://cdn.example.com/live/720p.m3u8'],
      segmentUrls: <String>[],
      reasons: <String>['Manifest is reachable and HLS-like.'],
      recommendations: <String>['Continue with stream startup.'],
      userMessage: 'The stream looks reachable.',
      developerMessage: 'HLS manifest probe completed.',
      analyzedAtMillis: 1716470400000,
      redirectCount: 1,
      elapsedMillis: 125,
      manifestByteLength: 512,
      probeStage: 'manifestParsing',
      errorCode: null,
    );

    test('stores all fields', () {
      expect(result.url, 'https://example.com/live/master.m3u8');
      expect(result.finalUrl, 'https://cdn.example.com/live/master.m3u8');
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
        'https://cdn.example.com/live/720p.m3u8',
      ]);
      expect(result.segmentUrls, isEmpty);
      expect(result.reasons, <String>['Manifest is reachable and HLS-like.']);
      expect(result.recommendations, <String>['Continue with stream startup.']);
      expect(result.userMessage, 'The stream looks reachable.');
      expect(result.developerMessage, 'HLS manifest probe completed.');
      expect(result.analyzedAtMillis, 1716470400000);
      expect(result.redirectCount, 1);
      expect(result.elapsedMillis, 125);
      expect(result.manifestByteLength, 512);
      expect(result.probeStage, 'manifestParsing');
      expect(result.errorCode, isNull);
    });

    test('toMap returns stable fields', () {
      expect(result.toMap(), <String, Object?>{
        'url': 'https://example.com/live/master.m3u8',
        'finalUrl': 'https://cdn.example.com/live/master.m3u8',
        'riskLevel': 'low',
        'severity': 'info',
        'canContinue': true,
        'statusCode': 200,
        'contentType': 'application/vnd.apple.mpegurl',
        'isReachable': true,
        'isManifestReadable': true,
        'isLikelyHls': true,
        'hasVariantStreams': true,
        'hasMediaSegments': false,
        'variantUrls': <String>['https://cdn.example.com/live/720p.m3u8'],
        'segmentUrls': <String>[],
        'reasons': <String>['Manifest is reachable and HLS-like.'],
        'recommendations': <String>['Continue with stream startup.'],
        'userMessage': 'The stream looks reachable.',
        'developerMessage': 'HLS manifest probe completed.',
        'analyzedAtMillis': 1716470400000,
        'redirectCount': 1,
        'elapsedMillis': 125,
        'manifestByteLength': 512,
        'probeStage': 'manifestParsing',
        'errorCode': null,
        'hlsPlaylistType': 'master',
      });
    });

    test('fromMap reads stable fields', () {
      final NativeLensStreamProbeResult decoded =
          NativeLensStreamProbeResult.fromMap(result.toMap());

      expect(decoded.url, result.url);
      expect(decoded.finalUrl, result.finalUrl);
      expect(decoded.riskLevel, result.riskLevel);
      expect(decoded.severity, result.severity);
      expect(decoded.canContinue, result.canContinue);
      expect(decoded.statusCode, result.statusCode);
      expect(decoded.contentType, result.contentType);
      expect(decoded.isReachable, result.isReachable);
      expect(decoded.isManifestReadable, result.isManifestReadable);
      expect(decoded.isLikelyHls, result.isLikelyHls);
      expect(decoded.hlsPlaylistType, result.hlsPlaylistType);
      expect(decoded.isMasterPlaylist, isTrue);
      expect(decoded.isMediaPlaylist, isFalse);
      expect(decoded.hasVariantStreams, result.hasVariantStreams);
      expect(decoded.hasMediaSegments, result.hasMediaSegments);
      expect(decoded.variantUrls, result.variantUrls);
      expect(decoded.segmentUrls, result.segmentUrls);
      expect(decoded.reasons, result.reasons);
      expect(decoded.recommendations, result.recommendations);
      expect(decoded.userMessage, result.userMessage);
      expect(decoded.developerMessage, result.developerMessage);
      expect(decoded.analyzedAtMillis, result.analyzedAtMillis);
      expect(decoded.redirectCount, result.redirectCount);
      expect(decoded.elapsedMillis, result.elapsedMillis);
      expect(decoded.manifestByteLength, result.manifestByteLength);
      expect(decoded.probeStage, result.probeStage);
      expect(decoded.errorCode, result.errorCode);
    });

    test('list fields are immutable and detached from constructor input', () {
      final List<String> variantUrls = <String>[
        'https://cdn.example.com/live/720p.m3u8',
      ];
      final List<String> reasons = <String>['Manifest is readable.'];

      final NativeLensStreamProbeResult safeResult =
          NativeLensStreamProbeResult(
            url: 'https://example.com/live/master.m3u8',
            finalUrl: 'https://example.com/live/master.m3u8',
            riskLevel: 'medium',
            severity: 'warning',
            canContinue: true,
            isReachable: true,
            isManifestReadable: true,
            isLikelyHls: true,
            hasVariantStreams: true,
            hasMediaSegments: false,
            variantUrls: variantUrls,
            segmentUrls: <String>[],
            reasons: reasons,
            recommendations: <String>['Warn before playback.'],
            userMessage: 'The stream may work.',
            developerMessage: 'Probe found a readable manifest.',
            analyzedAtMillis: 1716470400000,
            probeStage: 'manifestParsing',
          );

      variantUrls.add('https://cdn.example.com/live/1080p.m3u8');
      reasons.add('Caller mutated the original list.');

      expect(safeResult.variantUrls, <String>[
        'https://cdn.example.com/live/720p.m3u8',
      ]);
      expect(safeResult.reasons, <String>['Manifest is readable.']);
      expect(() => safeResult.variantUrls.add('new'), throwsUnsupportedError);
      expect(() => safeResult.reasons.add('new'), throwsUnsupportedError);
    });

    test('fromMap keeps old response maps compatible', () {
      final Map<String, Object?> oldMap = Map<String, Object?>.from(
        result.toMap(),
      )..remove('hlsPlaylistType');

      final NativeLensStreamProbeResult decoded =
          NativeLensStreamProbeResult.fromMap(oldMap);

      expect(decoded.hlsPlaylistType, isNull);
      expect(decoded.isMasterPlaylist, isFalse);
      expect(decoded.isMediaPlaylist, isFalse);
    });

    test('toString contains url and riskLevel', () {
      expect(result.toString(), contains('NativeLensStreamProbeResult'));
      expect(
        result.toString(),
        contains('https://example.com/live/master.m3u8'),
      );
      expect(result.toString(), contains('low'));
    });
  });
}
