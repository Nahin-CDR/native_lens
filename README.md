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
  native_lens: ^0.1.0
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

## Repository

- Homepage: https://github.com/Nahin-CDR/native_lens
- Repository: https://github.com/Nahin-CDR/native_lens
- Issues: https://github.com/Nahin-CDR/native_lens/issues
