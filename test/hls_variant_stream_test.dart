import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  test('HlsVariantStream stores and serializes all fields', () {
    const HlsVariantStream variant = HlsVariantStream(
      uri: '720p/index.m3u8',
      url: 'https://cdn.example.com/live/720p/index.m3u8',
      bandwidth: 2400000,
      averageBandwidth: 2100000,
      width: 1280,
      height: 720,
      codecs: 'avc1.4d401f,mp4a.40.2',
      frameRate: 59.94,
      audioGroup: 'audio-main',
      subtitlesGroup: 'subs-main',
      closedCaptionsGroup: 'cc-main',
      name: '720p',
    );

    expect(variant.toMap(), <String, Object?>{
      'uri': '720p/index.m3u8',
      'url': 'https://cdn.example.com/live/720p/index.m3u8',
      'bandwidth': 2400000,
      'averageBandwidth': 2100000,
      'width': 1280,
      'height': 720,
      'codecs': 'avc1.4d401f,mp4a.40.2',
      'frameRate': 59.94,
      'audioGroup': 'audio-main',
      'subtitlesGroup': 'subs-main',
      'closedCaptionsGroup': 'cc-main',
      'name': '720p',
    });
  });

  test('HlsVariantStream fromMap reads stable fields', () {
    final HlsVariantStream variant = HlsVariantStream.fromMap(<String, Object?>{
      'uri': 'audio/index.m3u8',
      'url': 'https://cdn.example.com/live/audio/index.m3u8',
      'bandwidth': 128000,
      'averageBandwidth': 96000,
      'width': 640,
      'height': 360,
      'codecs': 'mp4a.40.2',
      'frameRate': 30,
      'audioGroup': 'audio',
      'subtitlesGroup': 'subs',
      'closedCaptionsGroup': 'NONE',
      'name': 'Audio',
    });

    expect(variant.uri, 'audio/index.m3u8');
    expect(variant.url, 'https://cdn.example.com/live/audio/index.m3u8');
    expect(variant.bandwidth, 128000);
    expect(variant.averageBandwidth, 96000);
    expect(variant.width, 640);
    expect(variant.height, 360);
    expect(variant.codecs, 'mp4a.40.2');
    expect(variant.frameRate, 30.0);
    expect(variant.audioGroup, 'audio');
    expect(variant.subtitlesGroup, 'subs');
    expect(variant.closedCaptionsGroup, 'NONE');
    expect(variant.name, 'Audio');
  });

  test('HlsVariantStream fromMap safely defaults malformed fields', () {
    final HlsVariantStream variant = HlsVariantStream.fromMap(<String, Object?>{
      'uri': 7,
      'bandwidth': 'fast',
      'frameRate': 'smooth',
    });

    expect(variant.uri, isNull);
    expect(variant.bandwidth, isNull);
    expect(variant.frameRate, isNull);
    expect(variant.toString(), contains('HlsVariantStream'));
  });
}
