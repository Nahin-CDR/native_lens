import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens.dart';
import 'package:native_lens/native_lens_platform_interface.dart';
import 'package:native_lens/native_lens_method_channel.dart';
import 'package:native_lens/src/feature_mapping.dart';
import 'package:native_lens/src/preset_task_mapping.dart';
import 'package:native_lens/src/stream_probe_engine.dart';
import 'package:native_lens/src/streaming_readiness_mapping.dart';
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
  Stream<PowerState> watchPowerState() {
    return Stream<PowerState>.value(
      const PowerState(
        batteryLevel: 89,
        isCharging: true,
        chargingSource: 'USB',
        batteryHealth: 'Good',
        batteryStatus: 'Charging',
        batteryTemperatureCelsius: 31.6,
        isPowerSaveMode: false,
        isIgnoringBatteryOptimizations: false,
      ),
    );
  }

  @override
  Future<NativeLensThemeMode> getThemeMode() {
    return Future<NativeLensThemeMode>.value(NativeLensThemeMode.dark);
  }

  @override
  Stream<NativeLensThemeMode> watchThemeMode() {
    return Stream<NativeLensThemeMode>.value(NativeLensThemeMode.light);
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

class MockHevcPlatform extends MockNativeLensPlatform {
  @override
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return Future<List<MediaCodecCapability>>.value(
      const <MediaCodecCapability>[
        MediaCodecCapability(
          name: 'c2.android.hevc.encoder',
          isEncoder: true,
          supportedTypes: <String>['video/hevc'],
          isHardwareAccelerated: true,
          isSoftwareOnly: false,
          isVendor: false,
          supportedVideoTypes: <String>['video/hevc'],
          supportedAudioTypes: <String>[],
        ),
      ],
    );
  }
}

class MockNoMediaCodecPlatform extends MockNativeLensPlatform {
  @override
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return Future<List<MediaCodecCapability>>.value(<MediaCodecCapability>[]);
  }
}

class MockHighRiskPlatform extends MockNativeLensPlatform {
  @override
  Future<PowerState> getPowerState() {
    return Future<PowerState>.value(
      const PowerState(
        batteryLevel: 10,
        isCharging: false,
        chargingSource: 'Not charging',
        batteryHealth: 'Good',
        batteryStatus: 'Discharging',
        batteryTemperatureCelsius: 28.0,
        isPowerSaveMode: true,
        isIgnoringBatteryOptimizations: false,
      ),
    );
  }

  @override
  Future<NetworkCapability> getNetworkCapability() {
    return Future<NetworkCapability>.value(
      const NetworkCapability(
        isConnected: false,
        transportType: 'Disconnected',
        isValidated: false,
        isMetered: true,
        hasVpn: false,
        hasWifi: false,
        hasCellular: false,
        hasEthernet: false,
        hasBluetooth: false,
        hasLowLatency: false,
        hasHighBandwidth: false,
      ),
    );
  }

  @override
  Future<DisplayInfo> getDisplayInfo() {
    return Future<DisplayInfo>.value(
      const DisplayInfo(
        widthPixels: 1080,
        heightPixels: 2400,
        density: 2.75,
        densityDpi: 440,
        refreshRate: 30,
        supportedRefreshRates: <double>[30],
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

class MockDisconnectedNetworkPlatform extends MockNativeLensPlatform {
  @override
  Future<NetworkCapability> getNetworkCapability() {
    return Future<NetworkCapability>.value(
      const NetworkCapability(
        isConnected: false,
        transportType: 'Disconnected',
        isValidated: false,
        isMetered: false,
        hasVpn: false,
        hasWifi: false,
        hasCellular: false,
        hasEthernet: false,
        hasBluetooth: false,
        hasLowLatency: false,
        hasHighBandwidth: false,
      ),
    );
  }
}

class MockMeteredNetworkPlatform extends MockNativeLensPlatform {
  @override
  Future<NetworkCapability> getNetworkCapability() {
    return Future<NetworkCapability>.value(
      const NetworkCapability(
        isConnected: true,
        transportType: 'Cellular',
        isValidated: true,
        isMetered: true,
        hasVpn: false,
        hasWifi: false,
        hasCellular: true,
        hasEthernet: false,
        hasBluetooth: false,
        hasLowLatency: false,
        hasHighBandwidth: false,
      ),
    );
  }
}

class MockLowBatteryPlatform extends MockNativeLensPlatform {
  @override
  Future<PowerState> getPowerState() {
    return Future<PowerState>.value(
      const PowerState(
        batteryLevel: 8,
        isCharging: false,
        chargingSource: 'Not charging',
        batteryHealth: 'Good',
        batteryStatus: 'Discharging',
        batteryTemperatureCelsius: 29.0,
        isPowerSaveMode: false,
        isIgnoringBatteryOptimizations: false,
      ),
    );
  }
}

class MockNoCameraPlatform extends MockNativeLensPlatform {
  @override
  Future<List<CameraCapability>> getCameraCapabilities() {
    return Future<List<CameraCapability>>.value(<CameraCapability>[]);
  }
}

class MockMissingMotionSensorsPlatform extends MockNativeLensPlatform {
  @override
  Future<List<NativeSensor>> getSensors() {
    return Future<List<NativeSensor>>.value(<NativeSensor>[]);
  }
}

class MockMicrophonePlatform extends MockNativeLensPlatform {
  @override
  Future<List<SystemFeature>> getSystemFeatures() {
    return Future<List<SystemFeature>>.value(const <SystemFeature>[
      SystemFeature(
        name: 'android.hardware.touchscreen',
        version: null,
        isGlEsFeature: false,
      ),
      SystemFeature(
        name: 'android.hardware.microphone',
        version: null,
        isGlEsFeature: false,
      ),
      SystemFeature(name: 'OpenGL ES', version: 196608, isGlEsFeature: true),
    ]);
  }
}

Map<String, Object?> stableCustomTaskResultFields(
  NativeLensCustomTaskResult result,
) {
  return Map<String, Object?>.from(result.toMap())..remove('analyzedAtMillis');
}

Map<String, Object?> stableStreamProbeResultFields(
  NativeLensStreamProbeResult result,
) {
  return Map<String, Object?>.from(result.toMap())
    ..remove('analyzedAtMillis')
    ..remove('elapsedMillis');
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
    expect(summary.platformName, isNull);
    expect(summary.isIosNative, false);
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

  test('watchPowerState', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final PowerState powerState = await nativeLensPlugin
        .watchPowerState()
        .first;

    expect(powerState.batteryLevel, 89);
    expect(powerState.isCharging, true);
    expect(powerState.chargingSource, 'USB');
  });

  test('getThemeMode', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensThemeMode themeMode = await nativeLensPlugin.getThemeMode();

    expect(themeMode, NativeLensThemeMode.dark);
  });

  test('watchThemeMode', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensThemeMode themeMode = await nativeLensPlugin
        .watchThemeMode()
        .first;

    expect(themeMode, NativeLensThemeMode.light);
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
    expect(networkCapability.interfaceTypes, isNull);
    expect(networkCapability.isConstrained, isNull);
    expect(networkCapability.isIosNative, false);
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

  test('generateDatasetRow returns a valid row', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final int beforeGeneration = DateTime.now().millisecondsSinceEpoch;
    final NativeLensDatasetRow row = await nativeLensPlugin
        .generateDatasetRow();

    expect(row.isValid, isTrue);
    expect(row.schemaVersion, '1.0.0');
    expect(row.platform, 'android');
    expect(row.batteryLevel, 88);
    expect(row.networkConnected, isTrue);
    expect(row.networkValidated, isTrue);
    expect(row.cameraCount, 1);
    expect(row.sensorCount, 1);
    expect(row.codecCount, 2);
    expect(row.overallScore, 85);
    expect(row.riskLevel, 'low');
    expect(row.labelSource, 'rule_based_v1');
    expect(row.createdAtMillis, greaterThanOrEqualTo(beforeGeneration));
  });

  test('generateDatasetRow detects HEVC encoder when available', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockHevcPlatform fakePlatform = MockHevcPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensDatasetRow row = await nativeLensPlugin
        .generateDatasetRow();

    expect(row.hasHevcEncoder, isTrue);
  });

  test('generateDatasetRow detects missing HEVC encoder', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensDatasetRow row = await nativeLensPlugin
        .generateDatasetRow();

    expect(row.hasHevcEncoder, isFalse);
  });

  test(
    'generateDatasetRow normalizes risk level to high for limited results',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockHighRiskPlatform fakePlatform = MockHighRiskPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensDatasetRow row = await nativeLensPlugin
          .generateDatasetRow();

      expect(row.riskLevel, 'high');
    },
  );

  test('analyzeTaskRisk returns a valid offline result', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final int beforeAnalysis = DateTime.now().millisecondsSinceEpoch;
    final NativeTaskRiskResult result = await nativeLensPlugin.analyzeTaskRisk(
      task: NativeLensTask.videoUpload,
    );

    expect(result.task, NativeLensTask.videoUpload);
    expect(result.riskLevel, isIn(<String>['low', 'medium', 'high']));
    expect(result.confidence, greaterThanOrEqualTo(0));
    expect(result.confidence, lessThanOrEqualTo(1));
    expect(result.reasons, isNotEmpty);
    expect(result.recommendation, isNotEmpty);
    expect(result.analyzedAtMillis, greaterThanOrEqualTo(beforeAnalysis));
    expect(result.toMap()['riskLevel'], result.riskLevel);
  });

  test('analyzeTaskRisk includes capability fields', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeTaskRiskResult result = await nativeLensPlugin.analyzeTaskRisk(
      task: NativeLensTask.videoUpload,
    );

    expect(result.requiredCapabilities, contains('stable network'));
    expect(result.availableCapabilities, contains('stable network'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.toMap()['requiredCapabilities'], result.requiredCapabilities);
  });

  test(
    'analyzeTaskRisk returns high risk when upload network is disconnected',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockDisconnectedNetworkPlatform fakePlatform =
          MockDisconnectedNetworkPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeTaskRiskResult result = await nativeLensPlugin
          .analyzeTaskRisk(task: NativeLensTask.videoUpload);

      expect(result.riskLevel, 'high');
      expect(result.reasons, contains('Network is not connected.'));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
      expect(result.recommendation, contains('video upload'));
    },
  );

  test(
    'analyzeTaskRisk returns high risk when streaming network is disconnected',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockDisconnectedNetworkPlatform fakePlatform =
          MockDisconnectedNetworkPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeTaskRiskResult result = await nativeLensPlugin
          .analyzeTaskRisk(task: NativeLensTask.realtimeStreaming);

      expect(result.riskLevel, 'high');
      expect(result.reasons, contains('Network is not connected.'));
      expect(result.reasons, isNotEmpty);
      expect(result.recommendation, contains('realtime streaming'));
    },
  );

  test('analyzeTaskRisk detects low battery for video recording', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockLowBatteryPlatform fakePlatform = MockLowBatteryPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeTaskRiskResult result = await nativeLensPlugin.analyzeTaskRisk(
      task: NativeLensTask.videoRecording,
    );

    expect(result.riskLevel, isIn(<String>['medium', 'high']));
    expect(
      result.reasons,
      contains('Battery is below 10% and the device is not charging.'),
    );
    expect(result.confidence, greaterThanOrEqualTo(0));
    expect(result.confidence, lessThanOrEqualTo(1));
  });

  test(
    'analyzeTaskRisk returns high risk when camera capture has no camera',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNoCameraPlatform fakePlatform = MockNoCameraPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeTaskRiskResult result = await nativeLensPlugin
          .analyzeTaskRisk(task: NativeLensTask.cameraCapture);

      expect(result.riskLevel, 'high');
      expect(result.requiredCapabilities, contains('camera capability'));
      expect(result.missingCapabilities, contains('camera capability'));
      expect(result.reasons, contains('Camera capability is not available.'));
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
      expect(result.recommendation, isNotEmpty);
    },
  );

  test('analyzeTaskRisk reports missing capability for AR task', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockMissingMotionSensorsPlatform fakePlatform =
        MockMissingMotionSensorsPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeTaskRiskResult result = await nativeLensPlugin.analyzeTaskRisk(
      task: NativeLensTask.arExperience,
    );

    expect(result.riskLevel, 'high');
    expect(result.requiredCapabilities, contains('gyroscope sensor'));
    expect(result.requiredCapabilities, contains('accelerometer sensor'));
    expect(result.missingCapabilities, contains('gyroscope sensor'));
    expect(result.reasons, contains('Required gyroscope sensor is missing.'));
    expect(result.confidence, greaterThanOrEqualTo(0));
    expect(result.confidence, lessThanOrEqualTo(1));
    expect(result.recommendation, contains('non-AR fallback'));
  });

  test('analyzeTaskRisk recommendations change by task', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockDisconnectedNetworkPlatform fakePlatform =
        MockDisconnectedNetworkPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeTaskRiskResult uploadResult = await nativeLensPlugin
        .analyzeTaskRisk(task: NativeLensTask.videoUpload);
    final NativeTaskRiskResult streamingResult = await nativeLensPlugin
        .analyzeTaskRisk(task: NativeLensTask.realtimeStreaming);

    expect(uploadResult.recommendation, isNot(streamingResult.recommendation));
    expect(uploadResult.recommendation, contains('video upload'));
    expect(streamingResult.recommendation, contains('realtime streaming'));
  });

  test(
    'analyzeTaskRisk returns safe recommendation for healthy signals',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeTaskRiskResult result = await nativeLensPlugin
          .analyzeTaskRisk(task: NativeLensTask.videoUpload);

      expect(result.riskLevel, 'low');
      expect(result.reasons, isNotEmpty);
      expect(result.confidence, greaterThanOrEqualTo(0.80));
      expect(result.confidence, lessThanOrEqualTo(1));
      expect(result.recommendation, contains('Safe to continue'));
    },
  );

  test('analyzeCustomTask returns low risk for healthy requirements', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final int beforeAnalysis = DateTime.now().millisecondsSinceEpoch;
    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Face Filter Camera',
          requirements: const NativeLensTaskRequirements(
            requiresCamera: true,
            requiredSensors: <String>['accelerometer'],
            requiresStableNetwork: true,
            minBatteryLevel: 20,
          ),
        );

    expect(result, isA<NativeLensCustomTaskResult>());
    expect(result.taskName, 'Face Filter Camera');
    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('camera capability'));
    expect(result.requiredCapabilities, contains('stable network'));
    expect(result.requiredCapabilities, contains('accelerometer sensor'));
    expect(result.requiredCapabilities, contains('battery level >= 20%'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.availableCapabilities, contains('camera capability'));
    expect(result.availableCapabilities, contains('stable network'));
    expect(result.availableCapabilities, contains('accelerometer sensor'));
    expect(result.availableCapabilities, contains('battery level >= 20%'));
    expect(result.reasons, contains('Camera capability is available.'));
    expect(result.recommendations, <String>['Continue with the custom task.']);
    expect(result.userMessage, 'This feature looks ready on this device.');
    expect(result.developerMessage, contains('riskLevel=low'));
    expect(result.developerMessage, contains('missingCapabilities=none'));
    expect(
      result.developerMessage,
      contains('Camera capability is available.'),
    );
    expect(result.analyzedAtMillis, greaterThanOrEqualTo(beforeAnalysis));
  });

  test('analyzeFeature matches equivalent custom task analysis', () async {
    for (final NativeLensFeature feature in NativeLensFeature.values) {
      NativeLensPlatform.instance = MockNativeLensPlatform();
      final NativeLens nativeLensPlugin = NativeLens();

      final NativeLensCustomTaskResult featureResult = await nativeLensPlugin
          .analyzeFeature(feature);

      NativeLensPlatform.instance = MockNativeLensPlatform();
      final NativeLensCustomTaskResult customResult = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: nativeLensFeatureDisplayName(feature),
            requirements: nativeLensFeatureRequirements(feature),
          );

      expect(featureResult, isA<NativeLensCustomTaskResult>());
      expect(featureResult.taskName, nativeLensFeatureDisplayName(feature));
      expect(
        stableCustomTaskResultFields(featureResult),
        stableCustomTaskResultFields(customResult),
      );
    }
  });

  test('analyzeFeature faceFilterCamera uses mapped requirements', () async {
    NativeLens nativeLensPlugin = NativeLens();
    NativeLensPlatform.instance = MockNativeLensPlatform();

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeFeature(NativeLensFeature.faceFilterCamera);

    expect(result.taskName, 'Face Filter Camera');
    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.requiredCapabilities, contains('camera capability'));
    expect(result.requiredCapabilities, contains('gyroscope sensor'));
    expect(result.requiredCapabilities, contains('accelerometer sensor'));
    expect(result.requiredCapabilities, contains('battery level >= 20%'));
    expect(result.requiredCapabilities, contains('refresh rate >= 60Hz'));
    expect(result.availableCapabilities, contains('camera capability'));
    expect(result.availableCapabilities, contains('accelerometer sensor'));
    expect(result.missingCapabilities, contains('gyroscope sensor'));
  });

  test('analyzeFeature options affect result through mapping', () async {
    NativeLens nativeLensPlugin = NativeLens();
    NativeLensPlatform.instance = MockNativeLensPlatform();

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeFeature(
          NativeLensFeature.videoUpload,
          options: const NativeLensFeatureOptions(
            minBatteryLevel: 95,
            preferUnmeteredNetwork: true,
            disallowPowerSaveMode: true,
          ),
        );

    expect(result.taskName, 'Video Upload');
    expect(result.riskLevel, 'medium');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('stable network'));
    expect(result.requiredCapabilities, contains('unmetered network'));
    expect(result.requiredCapabilities, contains('power saver disabled'));
    expect(result.requiredCapabilities, contains('battery level >= 95%'));
    expect(result.availableCapabilities, contains('stable network'));
    expect(result.availableCapabilities, contains('unmetered network'));
    expect(result.availableCapabilities, contains('power saver disabled'));
    expect(result.missingCapabilities, contains('battery level >= 95%'));
  });

  test('analyzeStreamingReadiness delegates through custom engine', () async {
    NativeLensPlatform.instance = MockNativeLensPlatform();
    final NativeLens nativeLensPlugin = NativeLens();

    final NativeLensCustomTaskResult streamingResult = await nativeLensPlugin
        .analyzeStreamingReadiness();

    NativeLensPlatform.instance = MockNativeLensPlatform();
    final NativeLensCustomTaskResult customResult = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Streaming Readiness',
          requirements: nativeLensStreamingReadinessRequirements(
            const NativeLensFeatureOptions(),
          ),
        );

    expect(streamingResult, isA<NativeLensCustomTaskResult>());
    expect(streamingResult.taskName, 'Streaming Readiness');
    expect(
      stableCustomTaskResultFields(streamingResult),
      stableCustomTaskResultFields(customResult),
    );
    expect(streamingResult.requiredCapabilities, contains('stable network'));
    expect(
      streamingResult.requiredCapabilities,
      contains('media codec capability'),
    );
    expect(
      streamingResult.requiredCapabilities,
      contains('battery level >= 15%'),
    );
    expect(
      streamingResult.requiredCapabilities,
      contains('refresh rate >= 30Hz'),
    );
    expect(
      streamingResult.requiredCapabilities,
      contains('power saver disabled'),
    );
  });

  test('analyzeStreamingReadiness applies options through mapping', () async {
    NativeLensPlatform.instance = MockNativeLensPlatform();
    final NativeLens nativeLensPlugin = NativeLens();

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeStreamingReadiness(
          options: const NativeLensFeatureOptions(
            realtime: true,
            highPerformance: true,
            minBatteryLevel: 95,
            preferUnmeteredNetwork: true,
            disallowPowerSaveMode: true,
          ),
        );

    expect(result.taskName, 'Streaming Readiness');
    expect(result.riskLevel, 'medium');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('stable network'));
    expect(result.requiredCapabilities, contains('media codec capability'));
    expect(result.requiredCapabilities, contains('unmetered network'));
    expect(result.requiredCapabilities, contains('power saver disabled'));
    expect(result.requiredCapabilities, contains('battery level >= 95%'));
    expect(result.requiredCapabilities, contains('refresh rate >= 60Hz'));
    expect(result.availableCapabilities, contains('stable network'));
    expect(result.availableCapabilities, contains('media codec capability'));
    expect(result.availableCapabilities, contains('unmetered network'));
    expect(result.availableCapabilities, contains('power saver disabled'));
    expect(result.availableCapabilities, contains('refresh rate >= 60Hz'));
    expect(result.missingCapabilities, contains('battery level >= 95%'));
  });

  test('probeStreamingUrl delegates to internal engine', () async {
    await _withStreamProbeServer(
      body: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
''',
      contentType: 'application/vnd.apple.mpegurl',
      testBody: (String url) async {
        final NativeLens nativeLensPlugin = NativeLens();
        const NativeLensStreamProbeOptions options =
            NativeLensStreamProbeOptions();

        final NativeLensStreamProbeResult publicResult = await nativeLensPlugin
            .probeStreamingUrl(url: url, options: options);
        final NativeLensStreamProbeResult engineResult = await runStreamProbe(
          url: url,
          options: options,
        );

        expect(publicResult, isA<NativeLensStreamProbeResult>());
        expect(
          stableStreamProbeResultFields(publicResult),
          stableStreamProbeResultFields(engineResult),
        );
      },
    );
  });

  test('probeStreamingUrl returns low risk for valid HLS manifest', () async {
    await _withStreamProbeServer(
      body: '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
360p/index.m3u8
''',
      contentType: 'application/vnd.apple.mpegurl',
      testBody: (String url) async {
        final NativeLensStreamProbeResult result = await NativeLens()
            .probeStreamingUrl(url: url);

        expect(result.riskLevel, 'low');
        expect(result.canContinue, isTrue);
        expect(result.statusCode, 200);
        expect(result.isReachable, isTrue);
        expect(result.isManifestReadable, isTrue);
        expect(result.isLikelyHls, isTrue);
        expect(result.hasVariantStreams, isTrue);
        expect(result.variantUrls.single, endsWith('/360p/index.m3u8'));
        expect(result.hlsVariants, hasLength(1));
        expect(result.hlsVariants.single.bandwidth, 800000);
        expect(result.hlsSegments, isEmpty);
      },
    );
  });

  test('probeStreamingUrl returns high risk for invalid URL', () async {
    final NativeLensStreamProbeResult result = await NativeLens()
        .probeStreamingUrl(url: 'not a stream url');

    expect(result.riskLevel, 'high');
    expect(result.canContinue, isFalse);
    expect(result.errorCode, 'invalid_url');
    expect(result.probeStage, 'urlValidation');
  });

  test('probeStreamingUrl returns warning result for non-HLS body', () async {
    await _withStreamProbeServer(
      body: '<html><body>Not an HLS manifest</body></html>',
      contentType: 'text/html',
      path: '/index.html',
      testBody: (String url) async {
        final NativeLensStreamProbeResult result = await NativeLens()
            .probeStreamingUrl(url: url);

        expect(result.riskLevel, 'medium');
        expect(result.severity, 'warning');
        expect(result.canContinue, isTrue);
        expect(result.isReachable, isTrue);
        expect(result.isManifestReadable, isTrue);
        expect(result.isLikelyHls, isFalse);
        expect(result.errorCode, 'not_hls_manifest');
        expect(result.recommendations.single, contains('fallback'));
      },
    );
  });

  test('analyzePresetTask matches equivalent custom task analysis', () async {
    for (final NativeLensPreset preset in NativeLensPreset.values) {
      NativeLensPlatform.instance = MockNativeLensPlatform();
      final NativeLens nativeLensPlugin = NativeLens();

      final NativeLensCustomTaskResult presetResult = await nativeLensPlugin
          .analyzePresetTask(preset);

      NativeLensPlatform.instance = MockNativeLensPlatform();
      final NativeLensCustomTaskResult customResult = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: nativeLensPresetDisplayName(preset),
            requirements: nativeLensPresetRequirements(preset),
          );

      expect(presetResult, isA<NativeLensCustomTaskResult>());
      expect(presetResult.taskName, nativeLensPresetDisplayName(preset));
      expect(
        stableCustomTaskResultFields(presetResult),
        stableCustomTaskResultFields(customResult),
      );
    }
  });

  test('analyzePresetTask leaves existing task APIs unchanged', () async {
    NativeLens nativeLensPlugin = NativeLens();
    NativeLensPlatform.instance = MockNativeLensPlatform();

    final NativeTaskRiskResult taskRiskResult = await nativeLensPlugin
        .analyzeTaskRisk(task: NativeLensTask.videoUpload);

    expect(taskRiskResult.task, NativeLensTask.videoUpload);
    expect(taskRiskResult.riskLevel, 'low');

    NativeLensPlatform.instance = MockNativeLensPlatform();
    final NativeLensCustomTaskResult customTaskResult = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Manual Upload',
          requirements: const NativeLensTaskRequirements(
            requiresStableNetwork: true,
          ),
        );

    expect(customTaskResult.taskName, 'Manual Upload');
    expect(customTaskResult.riskLevel, 'low');
    expect(customTaskResult.requiredCapabilities, contains('stable network'));
  });

  test('analyzeCustomTask returns high risk when camera is missing', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNoCameraPlatform fakePlatform = MockNoCameraPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Camera Scan',
          requirements: const NativeLensTaskRequirements(requiresCamera: true),
        );

    expect(result.riskLevel, 'high');
    expect(result.severity, 'critical');
    expect(result.canContinue, isFalse);
    expect(result.requiredCapabilities, contains('camera capability'));
    expect(result.missingCapabilities, contains('camera capability'));
    expect(
      result.reasons,
      contains('Camera capability is required but unavailable.'),
    );
    expect(
      result.userMessage,
      'This feature may not work properly on this device.',
    );
    expect(
      result.developerMessage,
      contains('missingCapabilities=camera capability'),
    );
    expect(
      result.developerMessage,
      contains('Camera capability is required but unavailable.'),
    );
  });

  test(
    'analyzeCustomTask returns high risk when gyroscope is missing',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'AR Preview',
            requirements: const NativeLensTaskRequirements(
              requiredSensors: <String>['gyroscope'],
            ),
          );

      expect(result.riskLevel, 'high');
      expect(result.severity, 'critical');
      expect(result.canContinue, isFalse);
      expect(result.requiredCapabilities, contains('gyroscope sensor'));
      expect(result.missingCapabilities, contains('gyroscope sensor'));
      expect(
        result.reasons,
        contains('Gyroscope sensor is required but unavailable.'),
      );
    },
  );

  test(
    'analyzeCustomTask returns high risk when required network is disconnected',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockDisconnectedNetworkPlatform fakePlatform =
          MockDisconnectedNetworkPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'Live Sync',
            requirements: const NativeLensTaskRequirements(
              requiresStableNetwork: true,
            ),
          );

      expect(result.riskLevel, 'high');
      expect(result.severity, 'critical');
      expect(result.canContinue, isFalse);
      expect(result.requiredCapabilities, contains('stable network'));
      expect(result.missingCapabilities, contains('stable network'));
      expect(
        result.reasons,
        contains('Stable network is required but disconnected.'),
      );
    },
  );

  test(
    'analyzeCustomTask keeps low battery continuable without hard failures',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockLowBatteryPlatform fakePlatform = MockLowBatteryPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'Offline Export',
            requirements: const NativeLensTaskRequirements(minBatteryLevel: 20),
          );

      expect(result.riskLevel, isIn(<String>['medium', 'high']));
      expect(result.severity, isIn(<String>['warning', 'critical']));
      expect(result.canContinue, isTrue);
      expect(result.requiredCapabilities, contains('battery level >= 20%'));
      expect(result.missingCapabilities, contains('battery level >= 20%'));
      expect(
        result.reasons,
        contains('Battery is 8%, below the required 20%.'),
      );
      expect(
        result.userMessage,
        'This feature may not work properly on this device.',
      );
    },
  );

  test(
    'analyzeCustomTask returns high risk when microphone is missing',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'Voice Capture',
            requirements: const NativeLensTaskRequirements(
              requiresMicrophone: true,
            ),
          );

      expect(result.riskLevel, 'high');
      expect(result.severity, 'critical');
      expect(result.canContinue, isFalse);
      expect(result.requiredCapabilities, contains('microphone capability'));
      expect(result.missingCapabilities, contains('microphone capability'));
      expect(
        result.reasons,
        contains('Microphone capability is required but unavailable.'),
      );
      expect(result.recommendations, isNotEmpty);
    },
  );

  test('analyzeCustomTask reports available microphone capability', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockMicrophonePlatform fakePlatform = MockMicrophonePlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Voice Capture',
          requirements: const NativeLensTaskRequirements(
            requiresMicrophone: true,
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('microphone capability'));
    expect(result.availableCapabilities, contains('microphone capability'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.reasons, contains('Microphone capability is available.'));
  });

  test(
    'analyzeCustomTask returns high risk when system feature is missing',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
      NativeLensPlatform.instance = fakePlatform;

      const String featureName = 'android.hardware.location.gps';
      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'GPS Navigation',
            requirements: const NativeLensTaskRequirements(
              requiredSystemFeatures: <String>[featureName],
            ),
          );

      expect(result.riskLevel, 'high');
      expect(result.severity, 'critical');
      expect(result.canContinue, isFalse);
      expect(result.requiredCapabilities, contains(featureName));
      expect(result.missingCapabilities, contains(featureName));
      expect(
        result.reasons,
        contains('System feature $featureName is required but unavailable.'),
      );
    },
  );

  test('analyzeCustomTask reports available required system feature', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    const String featureName = 'android.hardware.touchscreen';
    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Touch Tool',
          requirements: const NativeLensTaskRequirements(
            requiredSystemFeatures: <String>[featureName],
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains(featureName));
    expect(result.availableCapabilities, contains(featureName));
    expect(result.missingCapabilities, isEmpty);
    expect(
      result.reasons,
      contains('System feature $featureName is available.'),
    );
  });

  test(
    'analyzeCustomTask returns high risk when media codecs are missing',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNoMediaCodecPlatform fakePlatform = MockNoMediaCodecPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'Media Export',
            requirements: const NativeLensTaskRequirements(
              requiresMediaCodecs: true,
            ),
          );

      expect(result.riskLevel, 'high');
      expect(result.severity, 'critical');
      expect(result.canContinue, isFalse);
      expect(result.requiredCapabilities, contains('media codec capability'));
      expect(result.missingCapabilities, contains('media codec capability'));
      expect(
        result.reasons,
        contains('Media codec capability is required but unavailable.'),
      );
      expect(result.recommendations, isNotEmpty);
    },
  );

  test('analyzeCustomTask reports available media codecs', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Media Export',
          requirements: const NativeLensTaskRequirements(
            requiresMediaCodecs: true,
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('media codec capability'));
    expect(result.availableCapabilities, contains('media codec capability'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.reasons, contains('Media codec capability is available.'));
  });

  test(
    'analyzeCustomTask returns medium risk when HEVC encoder is missing',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'HEVC Export',
            requirements: const NativeLensTaskRequirements(
              requiresHevcEncoder: true,
            ),
          );

      expect(result.riskLevel, 'medium');
      expect(result.severity, 'warning');
      expect(result.canContinue, isTrue);
      expect(result.requiredCapabilities, contains('HEVC encoder'));
      expect(result.missingCapabilities, contains('HEVC encoder'));
      expect(
        result.reasons,
        contains('HEVC encoder is unavailable; use H.264 fallback.'),
      );
      expect(
        result.recommendations,
        contains('Use H.264 fallback when HEVC is unavailable.'),
      );
      expect(
        result.userMessage,
        'This feature may work better with a few device or network improvements.',
      );
      expect(
        result.developerMessage,
        contains('missingCapabilities=HEVC encoder'),
      );
      expect(
        result.developerMessage,
        contains('HEVC encoder is unavailable; use H.264 fallback.'),
      );
    },
  );

  test('analyzeCustomTask reports available HEVC encoder', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockHevcPlatform fakePlatform = MockHevcPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'HEVC Export',
          requirements: const NativeLensTaskRequirements(
            requiresHevcEncoder: true,
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('HEVC encoder'));
    expect(result.availableCapabilities, contains('HEVC encoder'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.reasons, contains('HEVC encoder is available.'));
  });

  test('analyzeCustomTask reports low camera count as soft risk', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Multi Camera Capture',
          requirements: const NativeLensTaskRequirements(minCameraCount: 2),
        );

    expect(result.riskLevel, 'medium');
    expect(result.severity, 'warning');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('camera count >= 2'));
    expect(result.missingCapabilities, contains('camera count >= 2'));
    expect(
      result.reasons,
      contains('Camera count is 1, below the required 2.'),
    );
    expect(
      result.recommendations,
      contains(
        'Reduce camera-dependent quality requirements or provide a lower-camera fallback.',
      ),
    );
  });

  test('analyzeCustomTask reports low sensor count as soft risk', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Sensor Fusion',
          requirements: const NativeLensTaskRequirements(minSensorCount: 3),
        );

    expect(result.riskLevel, 'high');
    expect(result.severity, 'critical');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('sensor count >= 3'));
    expect(result.missingCapabilities, contains('sensor count >= 3'));
    expect(
      result.reasons,
      contains('Sensor count is 1, below the required 3.'),
    );
    expect(
      result.recommendations,
      contains(
        'Disable optional sensor-driven effects when sensor count is limited.',
      ),
    );
  });

  test('analyzeCustomTask reports low codec count as soft risk', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Codec Matrix',
          requirements: const NativeLensTaskRequirements(minCodecCount: 5),
        );

    expect(result.riskLevel, 'high');
    expect(result.severity, 'critical');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('codec count >= 5'));
    expect(result.missingCapabilities, contains('codec count >= 5'));
    expect(result.reasons, contains('Codec count is 2, below the required 5.'));
    expect(
      result.recommendations,
      contains('Use simpler media formats when codec availability is limited.'),
    );
  });

  test('analyzeCustomTask reports low refresh rate as soft risk', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'High FPS Effects',
          requirements: const NativeLensTaskRequirements(minRefreshRate: 144),
        );

    expect(result.riskLevel, 'medium');
    expect(result.severity, 'warning');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('refresh rate >= 144Hz'));
    expect(result.missingCapabilities, contains('refresh rate >= 144Hz'));
    expect(
      result.reasons,
      contains('Refresh rate is 120Hz, below the required 144Hz.'),
    );
    expect(
      result.recommendations,
      contains('Lower animation or FPS quality when refresh rate is limited.'),
    );
  });

  test('analyzeCustomTask passes count and refresh requirements', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Baseline Experience',
          requirements: const NativeLensTaskRequirements(
            minCameraCount: 1,
            minSensorCount: 1,
            minCodecCount: 2,
            minRefreshRate: 90,
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.missingCapabilities, isEmpty);
    expect(result.availableCapabilities, contains('camera count >= 1'));
    expect(result.availableCapabilities, contains('sensor count >= 1'));
    expect(result.availableCapabilities, contains('codec count >= 2'));
    expect(result.availableCapabilities, contains('refresh rate >= 90Hz'));
  });

  test(
    'analyzeCustomTask reports metered network when unmetered is required',
    () async {
      NativeLens nativeLensPlugin = NativeLens();
      MockMeteredNetworkPlatform fakePlatform = MockMeteredNetworkPlatform();
      NativeLensPlatform.instance = fakePlatform;

      final NativeLensCustomTaskResult result = await nativeLensPlugin
          .analyzeCustomTask(
            taskName: 'Large Upload',
            requirements: const NativeLensTaskRequirements(
              requiresUnmeteredNetwork: true,
            ),
          );

      expect(result.riskLevel, 'medium');
      expect(result.severity, 'warning');
      expect(result.canContinue, isTrue);
      expect(result.requiredCapabilities, contains('unmetered network'));
      expect(result.missingCapabilities, contains('unmetered network'));
      expect(
        result.reasons,
        contains(
          'Unmetered network is required but the active network is metered.',
        ),
      );
      expect(
        result.recommendations,
        contains('Use Wi-Fi or another unmetered network for this task.'),
      );
    },
  );

  test('analyzeCustomTask passes unmetered network requirement', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockNativeLensPlatform fakePlatform = MockNativeLensPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Large Upload',
          requirements: const NativeLensTaskRequirements(
            requiresUnmeteredNetwork: true,
          ),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('unmetered network'));
    expect(result.availableCapabilities, contains('unmetered network'));
    expect(result.missingCapabilities, isEmpty);
    expect(result.reasons, contains('Unmetered network is available.'));
  });

  test('analyzeCustomTask reports power saver when disallowed', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockHighRiskPlatform fakePlatform = MockHighRiskPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Realtime Effects',
          requirements: const NativeLensTaskRequirements(
            allowPowerSaveMode: false,
          ),
        );

    expect(result.riskLevel, 'medium');
    expect(result.severity, 'warning');
    expect(result.canContinue, isTrue);
    expect(result.requiredCapabilities, contains('power saver disabled'));
    expect(result.missingCapabilities, contains('power saver disabled'));
    expect(
      result.reasons,
      contains('Power saver mode is enabled but this task disallows it.'),
    );
    expect(
      result.recommendations,
      contains('Disable power saver mode for this task.'),
    );
  });

  test('analyzeCustomTask passes when power saver is allowed', () async {
    NativeLens nativeLensPlugin = NativeLens();
    MockHighRiskPlatform fakePlatform = MockHighRiskPlatform();
    NativeLensPlatform.instance = fakePlatform;

    final NativeLensCustomTaskResult result = await nativeLensPlugin
        .analyzeCustomTask(
          taskName: 'Background Mode',
          requirements: const NativeLensTaskRequirements(),
        );

    expect(result.riskLevel, 'low');
    expect(result.severity, 'info');
    expect(result.canContinue, isTrue);
    expect(result.missingCapabilities, isEmpty);
    expect(
      result.reasons,
      contains('No blocking custom task requirements were detected.'),
    );
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
    expect(networkCapability.interfaceTypes, isNull);
    expect(networkCapability.isConstrained, isNull);
    expect(networkCapability.isIosNative, false);
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

    final DeviceOrientationInfo orientation = await nativeLensPlugin
        .getDeviceOrientation();

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

Future<void> _withStreamProbeServer({
  required String body,
  required Future<void> Function(String url) testBody,
  String? contentType,
  String path = '/stream.m3u8',
  int statusCode = 200,
}) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  final StreamSubscription<HttpRequest> subscription = server.listen((
    HttpRequest request,
  ) {
    request.response.statusCode = statusCode;
    if (contentType != null) {
      request.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
    }
    request.response.write(body);
    unawaited(request.response.close());
  });

  try {
    await testBody('http://${server.address.host}:${server.port}$path');
  } finally {
    await subscription.cancel();
    await server.close(force: true);
  }
}
