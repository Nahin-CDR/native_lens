# NativeLens

NativeLens is a Flutter capability intelligence SDK with deep Android support
and initial iOS foundation support. It uses Platform Channels to inspect native
device capabilities, build runtime reports, and run offline compatibility
analysis from Dart.

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
  native_lens: ^0.4.0
```

Then run:

```sh
flutter pub get
```

## Platform Support

| Platform | Support level |
| --- | --- |
| Android | Deep native capability support for platform summary, sensors, display, media codecs, camera capabilities, power state, and network diagnostics |
| iOS | Foundation support with platform summary, power state, network capability, device orientation, and safe fallbacks for unsupported deep capability modules |

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

### Task Risk Analysis

NativeLens can analyze whether the current device state is suitable for
performance-sensitive tasks using offline native signals and explainable
rule-based intelligence.

Supported tasks:

- `videoUpload`
- `videoRecording`
- `audioRecording`
- `mediaProcessing`
- `backgroundSync`
- `cameraCapture`
- `realtimeStreaming`

```dart
final result = await NativeLens().analyzeTaskRisk(
  task: NativeLensTask.videoUpload,
);

print(result.riskLevel);
print(result.confidence);
print(result.reasons);
print(result.recommendation);
```

Sample output:

```text
riskLevel: high
confidence: 0.91
reasons:
- Battery is below 10% and the device is not charging.
- Network is not connected.

recommendation:
Delay video upload until the device is charging or network is stable.
```

Task risk analysis works offline. It does not require a server, Ollama, or an
ML model file. The result is derived from native device signals such as battery,
charging state, power saver mode, network status, codec support, camera
availability, refresh rate, sensor count, and compatibility score.

#### Capability Requirements

NativeLens can also check whether the current device has the required
capabilities for specific tasks. Capability checks use the same offline native
signals and can report required, available, and missing capabilities such as:

- camera
- stable network
- media codec support
- HEVC availability or H.264 fallback
- gyroscope
- accelerometer
- step counter or step detector
- magnetometer or compass

Supported capability-dependent tasks:

- `arExperience`
- `stepTracking`
- `compassNavigation`

```dart
final result = await NativeLens().analyzeTaskRisk(
  task: NativeLensTask.arExperience,
);

print(result.requiredCapabilities);
print(result.availableCapabilities);
print(result.missingCapabilities);
print(result.reasons);
print(result.recommendation);
```

Sample output:

```text
requiredCapabilities:
- camera
- gyroscope
- accelerometer

missingCapabilities:
- gyroscope

reasons:
- Required gyroscope sensor is missing.

recommendation:
Disable AR mode and provide a non-AR fallback experience.
```

Capability requirements work offline. They do not require a server, Ollama, or
an ML model file. NativeLens uses native device signals and explainable
rule-based intelligence, and it does not claim CPU, GPU, or chip-level
detection unless reliable platform APIs expose that data.

### Dataset Pipeline

Generate a stable dataset row from the current NativeLens report and
compatibility summary:

```dart
final NativeLensDatasetRow row = await nativeLens.generateDatasetRow();

print(row.platform);
print(row.overallScore);
print(row.riskLevel);
```

Export one row to JSON:

```dart
final String json = NativeLensDatasetExporter.toJson(row);

print(json);
```

Export one or more rows to CSV:

```dart
final String csv = NativeLensDatasetExporter.toCsv(<NativeLensDatasetRow>[row]);

print(csv);
```

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

- Deep Android capability support remains the primary focus.
- iOS support is currently foundational and safe-fallback oriented.
- No AI model yet.
- No macOS, Windows, Linux, or web implementation yet.

## Author

- Portfolio: https://bynahin.onrender.com/
- Pub.dev: https://pub.dev/packages/native_lens

## Repository

- Homepage: https://github.com/Nahin-CDR/native_lens
- Repository: https://github.com/Nahin-CDR/native_lens
- Issues: https://github.com/Nahin-CDR/native_lens/issues
