import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/camera_capability.dart';
import 'package:native_lens/display_info.dart';
import 'package:native_lens/media_codec_capability.dart';
import 'package:native_lens/native_lens_method_channel.dart';
import 'package:native_lens/native_lens_theme_mode.dart';
import 'package:native_lens/native_sensor.dart';
import 'package:native_lens/network_capability.dart';
import 'package:native_lens/platform_summary.dart';
import 'package:native_lens/power_state.dart';
import 'package:native_lens/system_feature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNativeLens platform = MethodChannelNativeLens();
  const MethodChannel channel = MethodChannel('native_lens');
  const EventChannel powerStateChannel = EventChannel(
    'native_lens/power_state',
  );
  const EventChannel themeModeChannel = EventChannel('native_lens/theme_mode');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getSystemFeatures') {
            return <Map<String, Object?>>[
              <String, Object?>{
                'name': 'android.hardware.touchscreen',
                'version': null,
                'isGlEsFeature': false,
              },
              <String, Object?>{
                'name': 'OpenGL ES',
                'version': 196608,
                'isGlEsFeature': true,
              },
            ];
          }

          if (methodCall.method == 'getSensors') {
            return <Map<String, Object>>[
              <String, Object>{
                'name': 'Pixel Accelerometer',
                'vendor': 'Google',
                'type': 1,
                'typeName': 'Accelerometer',
                'version': 1,
                'resolution': 0.01,
                'maximumRange': 39.2,
                'power': 0.12,
                'minDelay': 10000,
                'maxDelay': 1000000,
                'isWakeUpSensor': false,
              },
            ];
          }

          if (methodCall.method == 'getDisplayInfo') {
            return <String, Object>{
              'widthPixels': 1080,
              'heightPixels': 2400,
              'density': 2.75,
              'densityDpi': 440,
              'refreshRate': 120.0,
              'supportedRefreshRates': <double>[60.0, 90.0, 120.0],
              'isHdrSupported': true,
              'supportedHdrTypes': <String>['HDR10', 'HLG'],
            };
          }

          if (methodCall.method == 'getMediaCodecs') {
            return <Map<String, Object>>[
              <String, Object>{
                'name': 'c2.android.avc.decoder',
                'isEncoder': false,
                'supportedTypes': <String>['video/avc'],
                'isHardwareAccelerated': false,
                'isSoftwareOnly': true,
                'isVendor': false,
                'supportedVideoTypes': <String>['video/avc'],
                'supportedAudioTypes': <String>[],
              },
              <String, Object>{
                'name': 'c2.android.aac.encoder',
                'isEncoder': true,
                'supportedTypes': <String>['audio/mp4a-latm'],
                'isHardwareAccelerated': false,
                'isSoftwareOnly': true,
                'isVendor': false,
                'supportedVideoTypes': <String>[],
                'supportedAudioTypes': <String>['audio/mp4a-latm'],
              },
            ];
          }

          if (methodCall.method == 'getCameraCapabilities') {
            return <Map<String, Object>>[
              <String, Object>{
                'cameraId': '0',
                'lensFacing': 'Back',
                'hardwareLevel': 'Full',
                'hasFlash': true,
                'sensorOrientation': 90,
                'supportsRawCapture': true,
                'supportsManualSensor': true,
                'supportsManualPostProcessing': true,
                'supportsAutoFocus': true,
                'supportsOpticalStabilization': true,
                'supportedFpsRanges': <String>['15-30 fps', '30-60 fps'],
              },
            ];
          }

          if (methodCall.method == 'getPowerState') {
            return <String, Object>{
              'batteryLevel': 88,
              'isCharging': true,
              'chargingSource': 'USB',
              'batteryHealth': 'Good',
              'batteryStatus': 'Charging',
              'batteryTemperatureCelsius': 31.5,
              'isPowerSaveMode': false,
              'isIgnoringBatteryOptimizations': false,
            };
          }

          if (methodCall.method == 'getNetworkCapability') {
            return <String, Object>{
              'isConnected': true,
              'transportType': 'Wi-Fi',
              'isValidated': true,
              'isMetered': false,
              'hasVpn': false,
              'hasWifi': true,
              'hasCellular': false,
              'hasEthernet': false,
              'hasBluetooth': false,
              'hasLowLatency': false,
              'hasHighBandwidth': false,
            };
          }

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(powerStateChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(themeModeChannel, null);
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
    expect(summary.platformName, 'android');
    expect(summary.osName, 'Android');
    expect(summary.osVersion, '15');
    expect(summary.isIosNative, false);
    expect(summary.localizedModel, isNull);
    expect(summary.physicalMemoryBytes, isNull);
  });

  test('PlatformSummary parses iOS native baseline fields', () {
    final PlatformSummary summary = PlatformSummary.fromMap(<Object?, Object?>{
      'manufacturer': 'Apple',
      'brand': 'Apple',
      'model': 'iPhone',
      'device': 'iPhone',
      'product': 'iPhone',
      'androidSdk': 0,
      'androidRelease': '18.5',
      'platformName': 'ios',
      'osName': 'iOS',
      'osVersion': '18.5',
      'localizedModel': 'iPhone',
      'appEnvironment': 'simulator',
      'isPhysicalDevice': false,
      'isSimulator': true,
      'physicalMemoryBytes': 8589934592,
      'processorCount': 8,
      'activeProcessorCount': 6,
      'thermalState': 'nominal',
      'isIosNative': true,
    });

    expect(summary.manufacturer, 'Apple');
    expect(summary.brand, 'Apple');
    expect(summary.model, 'iPhone');
    expect(summary.androidSdk, 0);
    expect(summary.platformName, 'ios');
    expect(summary.osName, 'iOS');
    expect(summary.osVersion, '18.5');
    expect(summary.localizedModel, 'iPhone');
    expect(summary.appEnvironment, 'simulator');
    expect(summary.isPhysicalDevice, false);
    expect(summary.isSimulator, true);
    expect(summary.physicalMemoryBytes, 8589934592);
    expect(summary.processorCount, 8);
    expect(summary.activeProcessorCount, 6);
    expect(summary.thermalState, 'nominal');
    expect(summary.isIosNative, true);
  });

  test('getSystemFeatures', () async {
    final List<SystemFeature> features = await platform.getSystemFeatures();

    expect(features.length, 2);
    expect(features.first.name, 'android.hardware.touchscreen');
    expect(features.first.version, isNull);
    expect(features.first.isGlEsFeature, false);
    expect(features.last.name, 'OpenGL ES');
    expect(features.last.version, 196608);
    expect(features.last.isGlEsFeature, true);
  });

  test('getSensors', () async {
    final List<NativeSensor> sensors = await platform.getSensors();

    expect(sensors.length, 1);
    expect(sensors.first.name, 'Pixel Accelerometer');
    expect(sensors.first.vendor, 'Google');
    expect(sensors.first.type, 1);
    expect(sensors.first.typeName, 'Accelerometer');
    expect(sensors.first.version, 1);
    expect(sensors.first.resolution, 0.01);
    expect(sensors.first.maximumRange, 39.2);
    expect(sensors.first.power, 0.12);
    expect(sensors.first.minDelay, 10000);
    expect(sensors.first.maxDelay, 1000000);
    expect(sensors.first.isWakeUpSensor, false);
  });

  test('getDisplayInfo', () async {
    final DisplayInfo displayInfo = await platform.getDisplayInfo();

    expect(displayInfo.widthPixels, 1080);
    expect(displayInfo.heightPixels, 2400);
    expect(displayInfo.density, 2.75);
    expect(displayInfo.densityDpi, 440);
    expect(displayInfo.refreshRate, 120);
    expect(displayInfo.supportedRefreshRates, <double>[60, 90, 120]);
    expect(displayInfo.isHdrSupported, true);
    expect(displayInfo.supportedHdrTypes, <String>['HDR10', 'HLG']);
    expect(displayInfo.widthPoints, isNull);
    expect(displayInfo.heightPoints, isNull);
    expect(displayInfo.nativeScale, isNull);
    expect(displayInfo.nativeWidthPixels, isNull);
    expect(displayInfo.nativeHeightPixels, isNull);
    expect(displayInfo.brightness, isNull);
    expect(displayInfo.isIosNative, false);
  });

  test('DisplayInfo parses iOS native baseline fields', () {
    final DisplayInfo displayInfo = DisplayInfo.fromMap(<Object?, Object?>{
      'widthPixels': 1179,
      'heightPixels': 2556,
      'density': 3.0,
      'densityDpi': 480,
      'refreshRate': 120.0,
      'supportedRefreshRates': <double>[120.0],
      'isHdrSupported': false,
      'supportedHdrTypes': <String>[],
      'widthPoints': 393.0,
      'heightPoints': 852.0,
      'nativeScale': 3.0,
      'nativeWidthPixels': 1179,
      'nativeHeightPixels': 2556,
      'brightness': 0.75,
      'isIosNative': true,
    });

    expect(displayInfo.widthPixels, 1179);
    expect(displayInfo.heightPixels, 2556);
    expect(displayInfo.density, 3.0);
    expect(displayInfo.densityDpi, 480);
    expect(displayInfo.refreshRate, 120.0);
    expect(displayInfo.supportedRefreshRates, <double>[120.0]);
    expect(displayInfo.isHdrSupported, false);
    expect(displayInfo.supportedHdrTypes, <String>[]);
    expect(displayInfo.widthPoints, 393.0);
    expect(displayInfo.heightPoints, 852.0);
    expect(displayInfo.nativeScale, 3.0);
    expect(displayInfo.nativeWidthPixels, 1179);
    expect(displayInfo.nativeHeightPixels, 2556);
    expect(displayInfo.brightness, 0.75);
    expect(displayInfo.isIosNative, true);
  });

  test('getMediaCodecs', () async {
    final List<MediaCodecCapability> codecs = await platform.getMediaCodecs();

    expect(codecs.length, 2);
    expect(codecs.first.name, 'c2.android.avc.decoder');
    expect(codecs.first.isEncoder, false);
    expect(codecs.first.supportedTypes, <String>['video/avc']);
    expect(codecs.first.isHardwareAccelerated, false);
    expect(codecs.first.isSoftwareOnly, true);
    expect(codecs.first.isVendor, false);
    expect(codecs.first.supportedVideoTypes, <String>['video/avc']);
    expect(codecs.first.supportedAudioTypes, <String>[]);
    expect(codecs.last.name, 'c2.android.aac.encoder');
    expect(codecs.last.isEncoder, true);
    expect(codecs.last.supportedAudioTypes, <String>['audio/mp4a-latm']);
  });

  test('getCameraCapabilities', () async {
    final List<CameraCapability> cameras = await platform
        .getCameraCapabilities();

    expect(cameras.length, 1);
    expect(cameras.first.cameraId, '0');
    expect(cameras.first.lensFacing, 'Back');
    expect(cameras.first.hardwareLevel, 'Full');
    expect(cameras.first.hasFlash, true);
    expect(cameras.first.sensorOrientation, 90);
    expect(cameras.first.supportsRawCapture, true);
    expect(cameras.first.supportsManualSensor, true);
    expect(cameras.first.supportsManualPostProcessing, true);
    expect(cameras.first.supportsAutoFocus, true);
    expect(cameras.first.supportsOpticalStabilization, true);
    expect(cameras.first.supportedFpsRanges, <String>[
      '15-30 fps',
      '30-60 fps',
    ]);
  });

  test('getPowerState', () async {
    final PowerState powerState = await platform.getPowerState();

    expect(powerState.batteryLevel, 88);
    expect(powerState.isCharging, true);
    expect(powerState.chargingSource, 'USB');
    expect(powerState.batteryHealth, 'Good');
    expect(powerState.batteryStatus, 'Charging');
    expect(powerState.batteryTemperatureCelsius, 31.5);
    expect(powerState.isPowerSaveMode, false);
    expect(powerState.isIgnoringBatteryOptimizations, false);
    expect(powerState.batteryState, isNull);
    expect(powerState.isBatteryMonitoringEnabled, isNull);
    expect(powerState.isBatteryMonitoringAvailable, isNull);
    expect(powerState.thermalState, isNull);
    expect(powerState.isIosNative, false);
  });

  test('PowerState parses iOS native baseline fields', () {
    final PowerState powerState = PowerState.fromMap(<Object?, Object?>{
      'batteryLevel': 76,
      'isCharging': true,
      'chargingSource': 'Charging',
      'batteryHealth': 'Unknown',
      'batteryStatus': 'Charging',
      'batteryTemperatureCelsius': 0.0,
      'isPowerSaveMode': true,
      'isIgnoringBatteryOptimizations': false,
      'batteryState': 'charging',
      'isBatteryMonitoringEnabled': true,
      'isBatteryMonitoringAvailable': true,
      'thermalState': 'nominal',
      'isIosNative': true,
    });

    expect(powerState.batteryLevel, 76);
    expect(powerState.isCharging, true);
    expect(powerState.chargingSource, 'Charging');
    expect(powerState.batteryHealth, 'Unknown');
    expect(powerState.batteryStatus, 'Charging');
    expect(powerState.batteryTemperatureCelsius, 0.0);
    expect(powerState.isPowerSaveMode, true);
    expect(powerState.isIgnoringBatteryOptimizations, false);
    expect(powerState.batteryState, 'charging');
    expect(powerState.isBatteryMonitoringEnabled, true);
    expect(powerState.isBatteryMonitoringAvailable, true);
    expect(powerState.thermalState, 'nominal');
    expect(powerState.isIosNative, true);
  });

  test('watchPowerState parses stream events', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          powerStateChannel,
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink events) {
              events.success(<String, Object>{
                'batteryLevel': 72,
                'isCharging': true,
                'chargingSource': 'USB',
                'batteryHealth': 'Good',
                'batteryStatus': 'Charging',
                'batteryTemperatureCelsius': 30.5,
                'isPowerSaveMode': false,
                'isIgnoringBatteryOptimizations': false,
              });
              events.endOfStream();
            },
          ),
        );

    final PowerState powerState = await platform.watchPowerState().first;

    expect(powerState.batteryLevel, 72);
    expect(powerState.isCharging, true);
    expect(powerState.chargingSource, 'USB');
    expect(powerState.batteryStatus, 'Charging');
    expect(powerState.batteryTemperatureCelsius, 30.5);
  });

  test('getThemeMode parses light dark and unknown', () async {
    final Map<String, NativeLensThemeMode> expectedValues =
        <String, NativeLensThemeMode>{
          'light': NativeLensThemeMode.light,
          'dark': NativeLensThemeMode.dark,
          'unknown': NativeLensThemeMode.unknown,
        };

    for (final MapEntry<String, NativeLensThemeMode> expectedValue
        in expectedValues.entries) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'getThemeMode') {
              return expectedValue.key;
            }

            return null;
          });

      expect(await platform.getThemeMode(), expectedValue.value);
    }
  });

  test('getThemeMode returns unknown for invalid or null payloads', () async {
    for (final Object? payload in <Object?>['system', 42, null]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'getThemeMode') {
              return payload;
            }

            return null;
          });

      expect(await platform.getThemeMode(), NativeLensThemeMode.unknown);
    }
  });

  test('watchThemeMode parses stream values', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          themeModeChannel,
          MockStreamHandler.inline(
            onListen: (Object? arguments, MockStreamHandlerEventSink events) {
              events.success('light');
              events.success('dark');
              events.success('unknown');
              events.success('invalid');
              events.success(null);
              events.endOfStream();
            },
          ),
        );

    expect(await platform.watchThemeMode().toList(), <NativeLensThemeMode>[
      NativeLensThemeMode.light,
      NativeLensThemeMode.dark,
      NativeLensThemeMode.unknown,
      NativeLensThemeMode.unknown,
      NativeLensThemeMode.unknown,
    ]);
  });

  test('getNetworkCapability', () async {
    final NetworkCapability networkCapability = await platform
        .getNetworkCapability();

    expect(networkCapability.isConnected, true);
    expect(networkCapability.transportType, 'Wi-Fi');
    expect(networkCapability.isValidated, true);
    expect(networkCapability.isMetered, false);
    expect(networkCapability.hasVpn, false);
    expect(networkCapability.hasWifi, true);
    expect(networkCapability.hasCellular, false);
    expect(networkCapability.hasEthernet, false);
    expect(networkCapability.hasBluetooth, false);
    expect(networkCapability.hasLowLatency, false);
    expect(networkCapability.hasHighBandwidth, false);
  });
}
