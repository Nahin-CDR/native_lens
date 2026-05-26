import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/camera_capability.dart';
import 'package:native_lens/display_info.dart';
import 'package:native_lens/media_codec_capability.dart';
import 'package:native_lens/native_lens_method_channel.dart';
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
