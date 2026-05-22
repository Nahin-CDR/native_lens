# NativeLens

NativeLens is a Flutter Android capability intelligence SDK. It uses Kotlin
Platform Channels to inspect native Android device capabilities, build runtime
reports, and run offline compatibility analysis from Dart.

NativeLens is designed for apps that need a clear, developer-friendly snapshot
of the device they are running on without adding a backend, AI service, or
heavy dashboard layer.

## Key Features

- Android platform summary, including manufacturer, brand, model, SDK, and
  Android release.
- System feature matrix from Android PackageManager.
- Sensor capability profiling from SensorManager.
- Display capability profiling, including density, refresh rates, and HDR.
- Media codec capability profiling, including encoder and decoder support.
- Camera2 capability profiling without opening the camera or requiring camera
  permission.
- Power and battery runtime state.
- Network capability snapshots and real-time network capability updates.
- App-level network speed stream based on this app UID traffic.
- Full NativeLens report aggregation.
- Offline compatibility summary using simple Dart rules.

## Installation

Add NativeLens to your `pubspec.yaml`:

```yaml
dependencies:
  native_lens: ^0.2.0
```

Then run:

```sh
flutter pub get
```

## Basic Usage

Import the package:

```dart
import 'package:native_lens/native_lens.dart';
```

Create a NativeLens instance:

```dart
final NativeLens nativeLens = NativeLens();
```

## What's new in v0.2.0

- Screen Debug Trace: debug-only assert-based screen traces for development.
- Device Orientation APIs: one-shot `getDeviceOrientation()` and `deviceOrientationStream`.
- Example app: refactored into a professional diagnostics dashboard UI.
- Android fix: use `Surface` rotation constants to resolve build issues.

### Screen Debug Trace

Wrap your screen widgets with `NativeLensScreenTrace` to print the current
screen name, source file path, and route name during development.

```dart
NativeLensScreenTrace(
  screenName: 'ProductDetailsScreen',
  filePath: 'lib/features/product/product_details_screen.dart',
  routeName: '/product-details',
  child: ProductDetailsView(),
)
```

On debug builds the console output will be:

```text
[NativeLens] Screen Debug
Screen: ProductDetailsScreen
File: lib/features/product/product_details_screen.dart
Route: /product-details
```

The trace is emitted only when asserts are enabled. It does not print in
release builds.

### Platform Summary

```dart
final PlatformSummary summary = await nativeLens.getPlatformSummary();

print(summary.manufacturer);
print(summary.model);
print(summary.androidRelease);
```

### Full Runtime Report

```dart
final NativeLensReport report = await nativeLens.generateReport();

print(report.platformSummary);
print('Features: ${report.systemFeatures.length}');
print('Sensors: ${report.sensors.length}');
print('Codecs: ${report.mediaCodecs.length}');
print('Cameras: ${report.cameraCapabilities.length}');
```

### Compatibility Summary

```dart
final CompatibilitySummary summary = await nativeLens.analyzeCompatibility();

print(summary.overallScore);
print(summary.overallLevel);
print(summary.warnings);
print(summary.recommendations);
```

The compatibility summary is generated locally with simple Dart rules. It does
not call an AI API, backend, paid service, or remote model.

### Live Network Capability Updates

```dart
final Stream<NetworkCapability> stream = nativeLens.networkCapabilityStream;

stream.listen((NetworkCapability capability) {
  print(capability.isConnected ? 'Connected' : 'Disconnected');
  print(capability.transportType);
});
```

### App Traffic Speed Stream

```dart
final Stream<NetworkSpeedSample> stream = nativeLens.networkSpeedStream;

stream.listen((NetworkSpeedSample sample) {
  print('Download: ${sample.rxKbps} kbps');
  print('Upload: ${sample.txKbps} kbps');
});
```

`networkSpeedStream` measures this app UID traffic with Android TrafficStats. It
is not a full internet speed test and does not use device-wide network stats.

### Device Orientation

Get the current device orientation snapshot from Android:

```dart
final DeviceOrientationInfo orientation =
    await nativeLens.getDeviceOrientation();

print(orientation.orientationName);
print(orientation.rotationDegrees);
print(orientation.isPortrait);
print(orientation.isLandscape);
```

Listen for live orientation updates:

```dart
nativeLens.deviceOrientationStream.listen((DeviceOrientationInfo orientation) {
  print('Orientation: ${orientation.orientationName}');
  print('Rotation degrees: ${orientation.rotationDegrees}');
});
```

## Privacy

NativeLens focuses on device capability and runtime state. It does not collect:

- Unique device identifiers.
- Contacts.
- Photos.
- Location.
- Device-wide network usage statistics.

Network speed samples are based on this app UID traffic only.

## Android Permissions

NativeLens uses:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

This permission is used for network capability detection, including connection
status, transport type, validated internet state, metered state, and related
network capability flags.

NativeLens does not request camera permission for camera capability profiling.
It reads Camera2 metadata only and does not open the camera or capture media.

## Current Limitations

- Android only.
- No AI model yet.
- No dashboard graphs yet.
- No iOS, macOS, Windows, Linux, or web implementation yet.

## Author

- Portfolio: https://bynahin.onrender.com/
- Pub.dev: https://pub.dev/packages/native_lens

## Repository

- Homepage: https://github.com/Nahin-CDR/native_lens
- Repository: https://github.com/Nahin-CDR/native_lens
- Issues: https://github.com/Nahin-CDR/native_lens/issues
