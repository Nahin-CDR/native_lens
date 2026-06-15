import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  test('HlsMediaSegment stores and serializes all fields', () {
    const HlsMediaSegment segment = HlsMediaSegment(
      uri: 'segments/segment-100.ts',
      url: 'https://cdn.example.com/live/segments/segment-100.ts',
      durationSeconds: 6.006,
      title: 'Opening segment',
      byteRange: '75232@0',
      isDiscontinuity: true,
      programDateTime: '2026-06-15T10:00:00.000Z',
      sequenceNumber: 100,
      keyMethod: 'AES-128',
      keyUri: 'https://cdn.example.com/live/key.bin',
    );

    expect(segment.toMap(), <String, Object?>{
      'uri': 'segments/segment-100.ts',
      'url': 'https://cdn.example.com/live/segments/segment-100.ts',
      'durationSeconds': 6.006,
      'title': 'Opening segment',
      'byteRange': '75232@0',
      'isDiscontinuity': true,
      'programDateTime': '2026-06-15T10:00:00.000Z',
      'sequenceNumber': 100,
      'keyMethod': 'AES-128',
      'keyUri': 'https://cdn.example.com/live/key.bin',
    });
  });

  test('HlsMediaSegment fromMap reads stable fields', () {
    final HlsMediaSegment segment = HlsMediaSegment.fromMap(<String, Object?>{
      'uri': 'segment-101.m4s',
      'url': 'https://cdn.example.com/live/segment-101.m4s',
      'durationSeconds': 4,
      'title': 'Segment 101',
      'byteRange': '4096',
      'isDiscontinuity': false,
      'programDateTime': '2026-06-15T10:00:06Z',
      'sequenceNumber': 101,
      'keyMethod': 'SAMPLE-AES',
      'keyUri': 'https://cdn.example.com/live/key-2.bin',
    });

    expect(segment.uri, 'segment-101.m4s');
    expect(segment.url, 'https://cdn.example.com/live/segment-101.m4s');
    expect(segment.durationSeconds, 4.0);
    expect(segment.title, 'Segment 101');
    expect(segment.byteRange, '4096');
    expect(segment.isDiscontinuity, isFalse);
    expect(segment.programDateTime, '2026-06-15T10:00:06Z');
    expect(segment.sequenceNumber, 101);
    expect(segment.keyMethod, 'SAMPLE-AES');
    expect(segment.keyUri, 'https://cdn.example.com/live/key-2.bin');
  });

  test('HlsMediaSegment fromMap safely defaults malformed fields', () {
    final HlsMediaSegment segment = HlsMediaSegment.fromMap(<String, Object?>{
      'uri': 7,
      'durationSeconds': 'long',
      'isDiscontinuity': 'yes',
      'sequenceNumber': '100',
    });

    expect(segment.uri, isNull);
    expect(segment.durationSeconds, isNull);
    expect(segment.isDiscontinuity, isFalse);
    expect(segment.sequenceNumber, isNull);
    expect(segment.toString(), contains('HlsMediaSegment'));
  });
}
