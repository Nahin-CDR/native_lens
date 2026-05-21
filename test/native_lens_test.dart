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

  @override
  Future<List<SystemFeature>> getSystemFeatures() {
    return Future<List<SystemFeature>>.value(const <SystemFeature>[
      SystemFeature(
        name: 'android.hardware.touchscreen',
        version: null,
        isGlEsFeature: false,
      ),
      SystemFeature(name: 'OpenGL ES', version: 196608, isGlEsFeature: true),
    ]);
  }

  @override
  Future<List<NativeSensor>> getSensors() {
    return Future<List<NativeSensor>>.value(const <NativeSensor>[
      NativeSensor(
        name: 'Pixel Accelerometer',
        vendor: 'Google',
        type: 1,
        typeName: 'Accelerometer',
        version: 1,
        resolution: 0.01,
        maximumRange: 39.2,
        power: 0.12,
        minDelay: 10000,
        maxDelay: 1000000,
        isWakeUpSensor: false,
      ),
    ]);
  }

  @override
  Future<DisplayInfo> getDisplayInfo() {
    return Future<DisplayInfo>.value(
      const DisplayInfo(
        widthPixels: 1080,
        heightPixels: 2400,
        density: 2.75,
        densityDpi: 440,
        refreshRate: 120,
        supportedRefreshRates: <double>[60, 90, 120],
        isHdrSupported: true,
        supportedHdrTypes: <String>['HDR10', 'HLG'],
      ),
    );
  }

  @override
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return Future<List<MediaCodecCapability>>.value(
      const <MediaCodecCapability>[
        MediaCodecCapability(
          name: 'c2.android.avc.decoder',
          isEncoder: false,
          supportedTypes: <String>['video/avc'],
          isHardwareAccelerated: false,
          isSoftwareOnly: true,
          isVendor: false,
          supportedVideoTypes: <String>['video/avc'],
          supportedAudioTypes: <String>[],
        ),
        MediaCodecCapability(
          name: 'c2.android.aac.encoder',
          isEncoder: true,
          supportedTypes: <String>['audio/mp4a-latm'],
          isHardwareAccelerated: false,
          isSoftwareOnly: true,
          isVendor: false,
          supportedVideoTypes: <String>[],
          supportedAudioTypes: <String>['audio/mp4a-latm'],
        ),
      ],
    );
  }

  @override
  Future<List<CameraCapability>> getCameraCapabilities() {
    return Future<List<CameraCapability>>.value(const <CameraCapability>[
      CameraCapability(
        cameraId: '0',
        lensFacing: 'Back',
        hardwareLevel: 'Full',
        hasFlash: true,
        sensorOrientation: 90,
        supportsRawCapture: true,
        supportsManualSensor: true,
        supportsManualPostProcessing: true,
        supportsAutoFocus: true,
        supportsOpticalStabilization: true,
        supportedFpsRanges: <String>['15-30 fps', '30-60 fps'],
      ),
    ]);
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

  test('getSystemFeatures', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final List<SystemFeature> features = await nativeLensPlugin
        .getSystemFeatures();

    expect(features.length, 2);
    expect(features.first.name, 'android.hardware.touchscreen');
    expect(features.last.isGlEsFeature, true);
  });

  test('getSensors', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final List<NativeSensor> sensors = await nativeLensPlugin.getSensors();

    expect(sensors.length, 1);
    expect(sensors.first.name, 'Pixel Accelerometer');
    expect(sensors.first.typeName, 'Accelerometer');
  });

  test('getDisplayInfo', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final DisplayInfo displayInfo = await nativeLensPlugin.getDisplayInfo();

    expect(displayInfo.widthPixels, 1080);
    expect(displayInfo.heightPixels, 2400);
    expect(displayInfo.refreshRate, 120);
    expect(displayInfo.isHdrSupported, true);
  });

  test('getMediaCodecs', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final List<MediaCodecCapability> codecs = await nativeLensPlugin
        .getMediaCodecs();

    expect(codecs.length, 2);
    expect(codecs.first.name, 'c2.android.avc.decoder');
    expect(codecs.first.isEncoder, false);
    expect(codecs.last.supportedAudioTypes, <String>['audio/mp4a-latm']);
  });

  test('getCameraCapabilities', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final List<CameraCapability> cameras = await nativeLensPlugin
        .getCameraCapabilities();

    expect(cameras.length, 1);
    expect(cameras.first.cameraId, '0');
    expect(cameras.first.lensFacing, 'Back');
    expect(cameras.first.supportsRawCapture, true);
  });
}
