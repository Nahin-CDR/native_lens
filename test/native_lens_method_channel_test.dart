import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/native_lens_method_channel.dart';
import 'package:native_lens/native_sensor.dart';
import 'package:native_lens/platform_summary.dart';
import 'package:native_lens/system_feature.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNativeLens platform = MethodChannelNativeLens();
  const MethodChannel channel = MethodChannel('native_lens');

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
}
