import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../native_lens_stream_probe_options.dart';
import '../native_lens_stream_probe_result.dart';
import 'stream_probe_manifest_parser.dart';

/// Internal HTTP response used by stream probe tests and implementations.
class StreamProbeHttpResponse {
  /// Creates an internal HTTP response.
  const StreamProbeHttpResponse({
    required this.statusCode,
    required this.bodyBytes,
    this.contentType,
    this.location,
  });

  /// HTTP status code returned by the response.
  final int statusCode;

  /// Raw response bytes.
  final List<int> bodyBytes;

  /// Response content type, when available.
  final String? contentType;

  /// Redirect location header, when available.
  final String? location;
}

/// Internal HTTP abstraction for stream probe tests and implementations.
abstract class StreamProbeHttpClient {
  /// Fetches the URL and returns a response without automatically redirecting.
  Future<StreamProbeHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  });
}

/// Runs an internal URL and manifest readiness probe.
Future<NativeLensStreamProbeResult> runStreamProbe({
  required String url,
  required NativeLensStreamProbeOptions options,
  StreamProbeHttpClient? httpClient,
}) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  final int analyzedAtMillis = DateTime.now().millisecondsSinceEpoch;
  final String originalUrl = url;
  final Uri? initialUri = Uri.tryParse(url.trim());

  if (initialUri == null || !initialUri.hasScheme || initialUri.host.isEmpty) {
    return _failureResult(
      url: originalUrl,
      finalUrl: originalUrl,
      analyzedAtMillis: analyzedAtMillis,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      probeStage: 'urlValidation',
      errorCode: 'invalid_url',
      reason: 'Stream URL is invalid.',
      recommendation: 'Use a valid absolute HTTP or HTTPS stream URL.',
      userMessage: 'The stream URL is invalid.',
      developerMessage:
          'Stream probe stopped during URL validation because the URL is invalid.',
    );
  }

  final Set<String> allowedSchemes = options.allowedSchemes
      .map((String scheme) => scheme.toLowerCase())
      .toSet();
  final String initialScheme = initialUri.scheme.toLowerCase();

  if (!allowedSchemes.contains(initialScheme)) {
    return _failureResult(
      url: originalUrl,
      finalUrl: initialUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      probeStage: 'urlValidation',
      errorCode: 'unsupported_scheme',
      reason: 'Stream URL scheme "$initialScheme" is not allowed.',
      recommendation: 'Use an allowed stream URL scheme before probing.',
      userMessage: 'The stream URL uses an unsupported scheme.',
      developerMessage:
          'Stream probe stopped because the URL scheme is not allowed.',
    );
  }

  if (options.requireHttps && initialScheme != 'https') {
    return _failureResult(
      url: originalUrl,
      finalUrl: initialUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      probeStage: 'urlValidation',
      errorCode: 'https_required',
      reason: 'HTTPS is required for this stream probe.',
      recommendation: 'Use an HTTPS stream URL.',
      userMessage: 'The stream URL must use HTTPS.',
      developerMessage:
          'Stream probe stopped because requireHttps is enabled and the URL is not HTTPS.',
    );
  }

  final StreamProbeHttpClient client =
      httpClient ?? _DartStreamProbeHttpClient();
  Uri currentUri = initialUri;
  StreamProbeHttpResponse? response;
  int redirectCount = 0;

  try {
    while (true) {
      response = await client
          .get(currentUri, headers: options.headers, timeout: options.timeout)
          .timeout(options.timeout);

      if (!_isRedirectStatus(response.statusCode)) {
        break;
      }

      final String? location = response.location;
      if (!options.followRedirects || location == null || location.isEmpty) {
        break;
      }

      if (redirectCount >= options.maxRedirects) {
        return _failureResult(
          url: originalUrl,
          finalUrl: currentUri.toString(),
          analyzedAtMillis: analyzedAtMillis,
          statusCode: response.statusCode,
          contentType: response.contentType,
          redirectCount: redirectCount,
          elapsedMillis: stopwatch.elapsedMilliseconds,
          probeStage: 'httpRequest',
          errorCode: 'too_many_redirects',
          reason: 'Stream URL exceeded the maximum redirect count.',
          recommendation: 'Use a stream URL with fewer redirects.',
          userMessage: 'The stream URL redirects too many times.',
          developerMessage:
              'Stream probe stopped because maxRedirects was exceeded.',
        );
      }

      final Uri redirectUri = currentUri.resolve(location);
      final String redirectScheme = redirectUri.scheme.toLowerCase();
      if (!allowedSchemes.contains(redirectScheme)) {
        return _failureResult(
          url: originalUrl,
          finalUrl: redirectUri.toString(),
          analyzedAtMillis: analyzedAtMillis,
          statusCode: response.statusCode,
          contentType: response.contentType,
          redirectCount: redirectCount,
          elapsedMillis: stopwatch.elapsedMilliseconds,
          probeStage: 'httpRequest',
          errorCode: 'unsupported_redirect_scheme',
          reason: 'Redirect URL scheme "$redirectScheme" is not allowed.',
          recommendation:
              'Use a stream URL that redirects only to allowed schemes.',
          userMessage: 'The stream URL redirects to an unsupported URL.',
          developerMessage:
              'Stream probe stopped because a redirect used an unsupported scheme.',
        );
      }

      if (options.requireHttps && redirectScheme != 'https') {
        return _failureResult(
          url: originalUrl,
          finalUrl: redirectUri.toString(),
          analyzedAtMillis: analyzedAtMillis,
          statusCode: response.statusCode,
          contentType: response.contentType,
          redirectCount: redirectCount,
          elapsedMillis: stopwatch.elapsedMilliseconds,
          probeStage: 'httpRequest',
          errorCode: 'https_required',
          reason: 'Redirect URL does not use HTTPS.',
          recommendation: 'Use a stream URL that redirects only to HTTPS URLs.',
          userMessage: 'The stream URL redirects to a non-HTTPS URL.',
          developerMessage:
              'Stream probe stopped because requireHttps is enabled and a redirect was not HTTPS.',
        );
      }

      redirectCount += 1;
      currentUri = redirectUri;
    }
  } on TimeoutException {
    return _failureResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      probeStage: 'httpRequest',
      errorCode: 'timeout',
      reason: 'Stream URL probe timed out.',
      recommendation: 'Retry later or show a fallback stream.',
      userMessage: 'The stream URL did not respond in time.',
      developerMessage:
          'Stream probe stopped because the HTTP request timed out.',
    );
  } on Object catch (error) {
    return _failureResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      probeStage: 'httpRequest',
      errorCode: 'http_error',
      reason: 'Stream URL probe failed before reading a manifest.',
      recommendation: 'Retry later or show a fallback stream.',
      userMessage: 'The stream URL could not be reached.',
      developerMessage: 'Stream probe HTTP request failed: $error',
    );
  }

  final StreamProbeHttpResponse finalResponse = response;
  final int manifestByteLength = finalResponse.bodyBytes.length;

  if (finalResponse.statusCode < 200 || finalResponse.statusCode >= 300) {
    return _failureResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      statusCode: finalResponse.statusCode,
      contentType: finalResponse.contentType,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      manifestByteLength: manifestByteLength,
      probeStage: 'httpRequest',
      errorCode: 'http_status',
      reason: 'Stream URL returned HTTP ${finalResponse.statusCode}.',
      recommendation: 'Use a reachable stream URL or show fallback content.',
      userMessage: 'The stream URL is not reachable right now.',
      developerMessage:
          'Stream probe stopped because the final HTTP status was ${finalResponse.statusCode}.',
    );
  }

  if (manifestByteLength > options.maxManifestBytes) {
    return _failureResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      analyzedAtMillis: analyzedAtMillis,
      statusCode: finalResponse.statusCode,
      contentType: finalResponse.contentType,
      isReachable: true,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      manifestByteLength: manifestByteLength,
      probeStage: 'manifestSize',
      errorCode: 'manifest_too_large',
      reason: 'Manifest response is larger than the configured probe limit.',
      recommendation: 'Use a smaller manifest or increase maxManifestBytes.',
      userMessage: 'The stream manifest is too large to probe safely.',
      developerMessage:
          'Stream probe stopped because manifestByteLength exceeded maxManifestBytes.',
    );
  }

  final String manifestBody = utf8.decode(
    finalResponse.bodyBytes,
    allowMalformed: true,
  );
  final StreamProbeManifestParseResult parseResult = parseStreamProbeManifest(
    manifestBody: manifestBody,
    baseUri: currentUri,
    extractVariantLimit: options.extractVariantLimit,
    extractSegmentLimit: options.extractSegmentLimit,
  );
  final bool isLikelyHls =
      parseResult.isLikelyHls ||
      _hasHlsContentType(finalResponse.contentType) ||
      currentUri.path.toLowerCase().endsWith('.m3u8');

  if (!isLikelyHls) {
    return NativeLensStreamProbeResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      riskLevel: 'medium',
      severity: 'warning',
      canContinue: true,
      statusCode: finalResponse.statusCode,
      contentType: finalResponse.contentType,
      isReachable: true,
      isManifestReadable: true,
      isLikelyHls: false,
      hlsPlaylistType: null,
      hasVariantStreams: false,
      hasMediaSegments: false,
      variantUrls: parseResult.variantUrls,
      segmentUrls: parseResult.segmentUrls,
      reasons: const <String>[
        'URL is reachable, but the response does not look like an HLS manifest.',
      ],
      recommendations: const <String>[
        'Warn the user or use a fallback stream before playback startup.',
      ],
      userMessage: 'The stream URL is reachable, but may not be an HLS stream.',
      developerMessage:
          'Stream probe completed with a reachable response that did not contain HLS manifest signals.',
      analyzedAtMillis: analyzedAtMillis,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      manifestByteLength: manifestByteLength,
      probeStage: 'manifestParsing',
      errorCode: 'not_hls_manifest',
    );
  }

  final bool hasPlaylistEntries =
      parseResult.hasVariantStreams || parseResult.hasMediaSegments;
  if (!hasPlaylistEntries) {
    return NativeLensStreamProbeResult(
      url: originalUrl,
      finalUrl: currentUri.toString(),
      riskLevel: 'medium',
      severity: 'warning',
      canContinue: true,
      statusCode: finalResponse.statusCode,
      contentType: finalResponse.contentType,
      isReachable: true,
      isManifestReadable: true,
      isLikelyHls: true,
      hlsPlaylistType: parseResult.hlsPlaylistType,
      hlsPlaylistSummary: parseResult.hlsPlaylistSummary,
      hlsVariants: parseResult.hlsVariants,
      hlsSegments: parseResult.hlsSegments,
      hasVariantStreams: false,
      hasMediaSegments: false,
      variantUrls: parseResult.variantUrls,
      segmentUrls: parseResult.segmentUrls,
      reasons: const <String>[
        'Manifest is reachable and HLS-like, but no variant playlists or media segments were found.',
      ],
      recommendations: const <String>[
        'Warn the user or use fallback content if playback startup fails.',
      ],
      userMessage: 'The stream manifest is reachable but may be incomplete.',
      developerMessage:
          'Stream probe completed with HLS-like manifest signals but no extracted playlist entries.',
      analyzedAtMillis: analyzedAtMillis,
      redirectCount: redirectCount,
      elapsedMillis: stopwatch.elapsedMilliseconds,
      manifestByteLength: manifestByteLength,
      probeStage: 'manifestParsing',
      errorCode: 'empty_hls_manifest',
    );
  }

  return NativeLensStreamProbeResult(
    url: originalUrl,
    finalUrl: currentUri.toString(),
    riskLevel: 'low',
    severity: 'info',
    canContinue: true,
    statusCode: finalResponse.statusCode,
    contentType: finalResponse.contentType,
    isReachable: true,
    isManifestReadable: true,
    isLikelyHls: true,
    hlsPlaylistType: parseResult.hlsPlaylistType,
    hlsPlaylistSummary: parseResult.hlsPlaylistSummary,
    hlsVariants: parseResult.hlsVariants,
    hlsSegments: parseResult.hlsSegments,
    hasVariantStreams: parseResult.hasVariantStreams,
    hasMediaSegments: parseResult.hasMediaSegments,
    variantUrls: parseResult.variantUrls,
    segmentUrls: parseResult.segmentUrls,
    reasons: const <String>[
      'URL is reachable and the manifest contains HLS readiness signals.',
    ],
    recommendations: const <String>[
      'Continue with playback startup while keeping normal player fallback handling.',
    ],
    userMessage: 'The stream URL looks ready to try.',
    developerMessage:
        'Stream probe completed successfully. This is URL and manifest readiness only, not a playback guarantee.',
    analyzedAtMillis: analyzedAtMillis,
    redirectCount: redirectCount,
    elapsedMillis: stopwatch.elapsedMilliseconds,
    manifestByteLength: manifestByteLength,
    probeStage: 'completed',
  );
}

NativeLensStreamProbeResult _failureResult({
  required String url,
  required String finalUrl,
  required int analyzedAtMillis,
  required int elapsedMillis,
  required String probeStage,
  required String errorCode,
  required String reason,
  required String recommendation,
  required String userMessage,
  required String developerMessage,
  int? statusCode,
  String? contentType,
  bool isReachable = false,
  int? redirectCount,
  int? manifestByteLength,
}) {
  return NativeLensStreamProbeResult(
    url: url,
    finalUrl: finalUrl,
    riskLevel: 'high',
    severity: 'critical',
    canContinue: false,
    statusCode: statusCode,
    contentType: contentType,
    isReachable: isReachable,
    isManifestReadable: false,
    isLikelyHls: false,
    hasVariantStreams: false,
    hasMediaSegments: false,
    variantUrls: const <String>[],
    segmentUrls: const <String>[],
    reasons: <String>[reason],
    recommendations: <String>[recommendation],
    userMessage: userMessage,
    developerMessage: developerMessage,
    analyzedAtMillis: analyzedAtMillis,
    redirectCount: redirectCount,
    elapsedMillis: elapsedMillis,
    manifestByteLength: manifestByteLength,
    probeStage: probeStage,
    errorCode: errorCode,
  );
}

bool _isRedirectStatus(int statusCode) {
  return statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}

bool _hasHlsContentType(String? contentType) {
  final String normalized = (contentType ?? '').toLowerCase();
  return normalized.contains('mpegurl') ||
      normalized.contains('x-mpegurl') ||
      normalized.contains('vnd.apple.mpegurl');
}

class _DartStreamProbeHttpClient implements StreamProbeHttpClient {
  @override
  Future<StreamProbeHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final HttpClient client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final HttpClientRequest request = await client
          .getUrl(uri)
          .timeout(timeout);
      request.followRedirects = false;

      for (final MapEntry<String, String> header in headers.entries) {
        request.headers.set(header.key, header.value);
      }

      final HttpClientResponse response = await request.close().timeout(
        timeout,
      );
      final List<int> bodyBytes = await response
          .fold<List<int>>(<int>[], (List<int> bytes, List<int> chunk) {
            bytes.addAll(chunk);
            return bytes;
          })
          .timeout(timeout);

      return StreamProbeHttpResponse(
        statusCode: response.statusCode,
        bodyBytes: bodyBytes,
        contentType: response.headers.contentType?.toString(),
        location: response.headers.value(HttpHeaders.locationHeader),
      );
    } finally {
      client.close(force: true);
    }
  }
}
