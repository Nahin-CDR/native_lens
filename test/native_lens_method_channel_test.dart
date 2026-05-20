import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens_method_channel.dart';
import 'package:native_lens/platform_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNativeLens platform = MethodChannelNativeLens();
  const MethodChannel channel = MethodChannel('native_lens');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'getPlatformSummary');

          return <String, Object>{
            'manufacturer': 'Google',
            'brand': 'google',
            'model': 'Pixel',
            'device': 'pixel',
            'product': 'pixel',
            'androidSdk': 35,
            'androidRelease': '15',
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformSummary', () async {
    final PlatformSummary summary = await platform.getPlatformSummary();

    expect(summary.manufacturer, 'Google');
    expect(summary.brand, 'google');
    expect(summary.model, 'Pixel');
    expect(summary.device, 'pixel');
    expect(summary.product, 'pixel');
    expect(summary.androidSdk, 35);
    expect(summary.androidRelease, '15');
  });
}
