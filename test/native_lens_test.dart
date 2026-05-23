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

  @override
  Future<PowerState> getPowerState() {
    return Future<PowerState>.value(
      const PowerState(
        batteryLevel: 88,
        isCharging: true,
        chargingSource: 'USB',
        batteryHealth: 'Good',
        batteryStatus: 'Charging',
        batteryTemperatureCelsius: 31.5,
        isPowerSaveMode: false,
        isIgnoringBatteryOptimizations: false,
      ),
    );
  }

  @override
  Future<NetworkCapability> getNetworkCapability() {
    return Future<NetworkCapability>.value(
      const NetworkCapability(
        isConnected: true,
        transportType: 'Wi-Fi',
        isValidated: true,
        isMetered: false,
        hasVpn: false,
        hasWifi: true,
        hasCellular: false,
        hasEthernet: false,
        hasBluetooth: false,
        hasLowLatency: false,
        hasHighBandwidth: false,
      ),
    );
  }

  @override
  Future<DeviceOrientationInfo> getDeviceOrientation() {
    return Future<DeviceOrientationInfo>.value(
      const DeviceOrientationInfo(
        orientationName: 'portraitUp',
        rotationDegrees: 0,
        isPortrait: true,
        isLandscape: false,
        source: 'display',
        timestampMillis: 123456789,
      ),
    );
  }

  @override
  Stream<DeviceOrientationInfo> get deviceOrientationStream {
    return Stream<DeviceOrientationInfo>.value(
      const DeviceOrientationInfo(
        orientationName: 'landscapeRight',
        rotationDegrees: 90,
        isPortrait: false,
        isLandscape: true,
        source: 'orientation',
        timestampMillis: 123456790,
      ),
    );
  }

  @override
  Stream<NetworkCapability> get networkCapabilityStream {
    return Stream<NetworkCapability>.value(
      const NetworkCapability(
        isConnected: true,
        transportType: 'Wi-Fi',
        isValidated: true,
        isMetered: false,
        hasVpn: false,
        hasWifi: true,
        hasCellular: false,
        hasEthernet: false,
        hasBluetooth: false,
        hasLowLatency: false,
        hasHighBandwidth: false,
      ),
    );
  }

  @override
  Stream<NetworkSpeedSample> get networkSpeedStream {
    return Stream<NetworkSpeedSample>.value(
      const NetworkSpeedSample(
        timestampMillis: 123456789,
        rxBytesPerSecond: 2048,
        txBytesPerSecond: 1024,
        rxKbps: 16.384,
        txKbps: 8.192,
        totalRxBytes: 4096,
        totalTxBytes: 2048,
        isSupported: true,
      ),
    );
  }
}

class MockIosFallbackPlatform extends MockNativeLensPlatform {
  @override
  Future<List<SystemFeature>> getSystemFeatures() {
    return Future<List<SystemFeature>>.value(<SystemFeature>[]);
  }

  @override
  Future<List<NativeSensor>> getSensors() {
    return Future<List<NativeSensor>>.value(<NativeSensor>[]);
  }

  @override
  Future<DisplayInfo> getDisplayInfo() {
    return Future<DisplayInfo>.value(
      const DisplayInfo(
        widthPixels: 375,
        heightPixels: 812,
        density: 3.0,
        densityDpi: 480,
        refreshRate: 60.0,
        supportedRefreshRates: <double>[60.0],
        isHdrSupported: false,
        supportedHdrTypes: <String>[],
      ),
    );
  }

  @override
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return Future<List<MediaCodecCapability>>.value(<MediaCodecCapability>[]);
  }

  @override
  Future<List<CameraCapability>> getCameraCapabilities() {
    return Future<List<CameraCapability>>.value(<CameraCapability>[]);
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

  test('getPowerState', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final PowerState powerState = await nativeLensPlugin.getPowerState();

    expect(powerState.batteryLevel, 88);
    expect(powerState.isCharging, true);
    expect(powerState.chargingSource, 'USB');
    expect(powerState.batteryHealth, 'Good');
  });

  test('getNetworkCapability', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NetworkCapability networkCapability = await nativeLensPlugin
        .getNetworkCapability();

    expect(networkCapability.isConnected, true);
    expect(networkCapability.transportType, 'Wi-Fi');
    expect(networkCapability.isValidated, true);
    expect(networkCapability.hasWifi, true);
  });

  test('generateReport', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;
    final int beforeReport = DateTime.now().millisecondsSinceEpoch;

    final NativeLensReport report = await nativeLensPlugin.generateReport();
    final Map<String, Object?> reportMap = report.toMap();

    expect(report.platformSummary.manufacturer, 'Google');
    expect(report.systemFeatures.length, 2);
    expect(report.sensors.length, 1);
    expect(report.mediaCodecs.length, 2);
    expect(report.cameraCapabilities.length, 1);
    expect(report.powerState.batteryLevel, 88);
    expect(report.networkCapability.transportType, 'Wi-Fi');
    expect(report.generatedAtMillis, greaterThanOrEqualTo(beforeReport));
    expect(reportMap['generatedAtMillis'], report.generatedAtMillis);
    expect(report.toString(), contains('NativeLensReport'));
  });

  test('generateReport with iOS fallback values', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockIosFallbackPlatform fakePlatform = MockIosFallbackPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensReport report = await nativeLensPlugin.generateReport();

    expect(report.systemFeatures, isEmpty);
    expect(report.sensors, isEmpty);
    expect(report.mediaCodecs, isEmpty);
    expect(report.cameraCapabilities, isEmpty);
    expect(report.displayInfo.widthPixels, 375);
    expect(report.powerState.isCharging, true);
    expect(report.networkCapability.transportType, 'Wi-Fi');
  });

  test('analyzeCompatibility', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final CompatibilitySummary summary = await nativeLensPlugin
        .analyzeCompatibility();
    final Map<String, Object> summaryMap = summary.toMap();

    expect(summary.overallScore, 85);
    expect(summary.overallLevel, 'Excellent');
    expect(summary.powerRiskLevel, 'Low');
    expect(summary.networkRiskLevel, 'Low');
    expect(summary.mediaCapabilityLevel, 'Low');
    expect(summary.cameraCapabilityLevel, 'High');
    expect(summary.displayCapabilityLevel, 'High');
    expect(summary.warnings, isEmpty);
    expect(
      summary.recommendations,
      contains('HEVC encoder is unavailable. Use H.264 fallback.'),
    );
    expect(summaryMap['overallScore'], summary.overallScore);
    expect(summary.toString(), contains('CompatibilitySummary'));
  });

  test('networkCapabilityStream', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NetworkCapability networkCapability =
        await nativeLensPlugin.networkCapabilityStream.first;

    expect(networkCapability.isConnected, true);
    expect(networkCapability.transportType, 'Wi-Fi');
    expect(networkCapability.hasWifi, true);
  });

  test('networkSpeedStream', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NetworkSpeedSample sample =
        await nativeLensPlugin.networkSpeedStream.first;

    expect(sample.rxBytesPerSecond, 2048);
    expect(sample.txBytesPerSecond, 1024);
    expect(sample.isSupported, true);
  });

  test('getDeviceOrientation', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final DeviceOrientationInfo orientation =
        await nativeLensPlugin.getDeviceOrientation();

    expect(orientation.orientationName, 'portraitUp');
    expect(orientation.rotationDegrees, 0);
    expect(orientation.isPortrait, true);
    expect(orientation.isLandscape, false);
  });

  test('deviceOrientationStream', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final DeviceOrientationInfo orientation =
        await nativeLensPlugin.deviceOrientationStream.first;

    expect(orientation.orientationName, 'landscapeRight');
    expect(orientation.rotationDegrees, 90);
    expect(orientation.isPortrait, false);
    expect(orientation.isLandscape, true);
  });
}
