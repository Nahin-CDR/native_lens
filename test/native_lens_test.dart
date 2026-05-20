import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';
import 'package:native_lens/native_lens_platform_interface.dart';
import 'package:native_lens/native_lens_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeLensPlatform
    with MockPlatformInterfaceMixin
    implements NativeLensPlatform {
  @override
  Future<PlatformSummary> getPlatformSummary() {
    return Future<PlatformSummary>.value(
      const PlatformSummary(
        manufacturer: 'Google',
        brand: 'google',
        model: 'Pixel',
        device: 'pixel',
        product: 'pixel',
        androidSdk: 35,
        androidRelease: '15',
      ),
    );
  }
}

void main() {
  final NativeLensPlatform initialPlatform = NativeLensPlatform.instance;

  test('$MethodChannelNativeLens is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeLens>());
  });

  test('getPlatformSummary', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final PlatformSummary summary = await nativeLensPlugin.getPlatformSummary();

    expect(summary.manufacturer, 'Google');
    expect(summary.androidSdk, 35);
  });
}
