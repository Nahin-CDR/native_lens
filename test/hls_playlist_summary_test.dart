import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  test('stores and serializes HLS playlist diagnostics', () {
    final HlsPlaylistSummary summary = HlsPlaylistSummary(
      playlistType: 'master',
      variantCount: 2,
      segmentCount: 0,
      targetDurationSeconds: 6,
      mediaSequence: 100,
      hasEncryption: true,
      hasDiscontinuity: true,
      hasByteRanges: true,
      maxBandwidth: 1400000,
      minBandwidth: 800000,
      maxResolutionWidth: 1280,
      maxResolutionHeight: 720,
      codecSummary: <String>['avc1.4d401e', 'mp4a.40.2'],
    );

    final Map<String, Object?> map = summary.toMap();
    final HlsPlaylistSummary decoded = HlsPlaylistSummary.fromMap(map);

    expect(decoded.toMap(), map);
    expect(decoded.playlistType, 'master');
    expect(decoded.variantCount, 2);
    expect(decoded.maxBandwidth, 1400000);
    expect(decoded.minBandwidth, 800000);
    expect(decoded.codecSummary, <String>['avc1.4d401e', 'mp4a.40.2']);
  });

  test('uses safe defaults for malformed maps', () {
    final HlsPlaylistSummary summary = HlsPlaylistSummary.fromMap(
      <String, Object?>{
        'playlistType': '',
        'variantCount': -1,
        'segmentCount': 'two',
        'totalDurationSeconds': double.nan,
        'targetDurationSeconds': -6,
        'mediaSequence': -100,
        'isLive': 'yes',
        'codecSummary': <Object?>['avc1.4d401e', null, 42, ''],
      },
    );

    expect(summary.playlistType, isNull);
    expect(summary.variantCount, 0);
    expect(summary.segmentCount, 0);
    expect(summary.totalDurationSeconds, isNull);
    expect(summary.targetDurationSeconds, isNull);
    expect(summary.mediaSequence, isNull);
    expect(summary.isLive, isFalse);
    expect(summary.codecSummary, <String>['avc1.4d401e']);
  });

  test('codec summary is immutable and detached from constructor input', () {
    final List<String> codecs = <String>['avc1.4d401e'];
    final HlsPlaylistSummary summary = HlsPlaylistSummary(codecSummary: codecs);

    codecs.add('mp4a.40.2');

    expect(summary.codecSummary, <String>['avc1.4d401e']);
    expect(() => summary.codecSummary.add('mp4a.40.2'), throwsUnsupportedError);
  });
}
