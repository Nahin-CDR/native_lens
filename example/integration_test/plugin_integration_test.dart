// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:native_lens/native_lens.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformSummary test', (WidgetTester tester) async {
    final NativeLens plugin = NativeLens();
    final PlatformSummary summary = await plugin.getPlatformSummary();

    // The values depend on the host device, so just assert the core fields
    // contain useful data.
    expect(summary.model.isNotEmpty, true);
    expect(summary.androidSdk > 0, true);
  });

  testWidgets('getSystemFeatures test', (WidgetTester tester) async {
    final NativeLens plugin = NativeLens();
    final List<SystemFeature> features = await plugin.getSystemFeatures();

    expect(features.isNotEmpty, true);
    expect(features.first.name.isNotEmpty, true);
  });

  testWidgets('getSensors test', (WidgetTester tester) async {
    final NativeLens plugin = NativeLens();
    final List<NativeSensor> sensors = await plugin.getSensors();

    expect(sensors.isNotEmpty, true);
    expect(sensors.first.name.isNotEmpty, true);
  });

  testWidgets('getDisplayInfo test', (WidgetTester tester) async {
    final NativeLens plugin = NativeLens();
    final DisplayInfo displayInfo = await plugin.getDisplayInfo();

    expect(displayInfo.widthPixels > 0, true);
    expect(displayInfo.heightPixels > 0, true);
  });

  testWidgets('getMediaCodecs test', (WidgetTester tester) async {
    final NativeLens plugin = NativeLens();
    final List<MediaCodecCapability> codecs = await plugin.getMediaCodecs();

    expect(codecs.isNotEmpty, true);
    expect(codecs.first.name.isNotEmpty, true);
  });
}
