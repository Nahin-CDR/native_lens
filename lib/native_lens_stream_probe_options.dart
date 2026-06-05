/// Options for URL and manifest readiness probing before streaming playback.
class NativeLensStreamProbeOptions {
  /// Creates stream probe options.
  const NativeLensStreamProbeOptions({
    this.timeout = const Duration(seconds: 8),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.maxManifestBytes = 1024 * 1024,
    this.extractSegmentLimit = 5,
    this.extractVariantLimit = 10,
    this.requireHttps = false,
    this.allowedSchemes = const <String>['http', 'https'],
    this.headers = const <String, String>{},
  });

  /// Maximum time allowed for the probe request.
  final Duration timeout;

  /// Whether HTTP redirects should be followed.
  final bool followRedirects;

  /// Maximum number of redirects to follow when redirects are enabled.
  final int maxRedirects;

  /// Maximum manifest response size to read, in bytes.
  final int maxManifestBytes;

  /// Maximum number of media segment URLs to extract from the manifest.
  final int extractSegmentLimit;

  /// Maximum number of variant playlist URLs to extract from the manifest.
  final int extractVariantLimit;

  /// Whether the input and final stream URL must use HTTPS.
  final bool requireHttps;

  /// URL schemes allowed by the probe.
  final List<String> allowedSchemes;

  /// Optional HTTP headers to send with the probe request.
  final Map<String, String> headers;
}
