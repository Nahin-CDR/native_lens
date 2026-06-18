import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  test('stores and serializes segment reachability diagnostics', () {
    const HlsSegmentReachability reachability = HlsSegmentReachability(
      checked: true,
      url: 'https://cdn.example.com/live/segment-001.ts',
      method: 'HEAD',
      isReachable: true,
      statusCode: 200,
      contentType: 'video/mp2t',
      contentLength: 75232,
      responseTimeMs: 42,
    );

    final Map<String, Object?> map = reachability.toMap();
    final HlsSegmentReachability decoded = HlsSegmentReachability.fromMap(map);

    expect(decoded.toMap(), map);
    expect(decoded.checked, isTrue);
    expect(decoded.method, 'HEAD');
    expect(decoded.isReachable, isTrue);
    expect(decoded.contentLength, 75232);
  });

  test('uses safe defaults for malformed maps', () {
    final HlsSegmentReachability reachability =
        HlsSegmentReachability.fromMap(<String, Object?>{
          'checked': 'yes',
          'url': '',
          'method': '',
          'isReachable': 'true',
          'statusCode': -1,
          'contentLength': -100,
          'responseTimeMs': 'fast',
          'errorType': '',
        });

    expect(reachability.checked, isFalse);
    expect(reachability.url, isNull);
    expect(reachability.method, isNull);
    expect(reachability.isReachable, isFalse);
    expect(reachability.statusCode, isNull);
    expect(reachability.contentLength, isNull);
    expect(reachability.responseTimeMs, isNull);
    expect(reachability.errorType, isNull);
  });
}
