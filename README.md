# NativeLens

NativeLens is a Flutter capability intelligence SDK with deep Android support
and privacy-safe iOS foundation support. It uses Platform Channels to inspect
native device capabilities, build runtime reports, and run offline
compatibility analysis from Dart.

NativeLens is designed for apps that need a clear, developer-friendly snapshot
of the device they are running on without adding a backend, AI service, or
heavy dashboard layer.

## Key Features

- Platform summary on Android and a safe iOS baseline for OS, model, runtime,
  memory, processors, and thermal state.
- System feature matrix from Android PackageManager.
- Sensor capability profiling from Android SensorManager.
- Display capability profiling, including density, refresh rates, HDR, and
  safe iOS screen metrics.
- Media codec capability profiling, including encoder and decoder support.
- Camera2 capability profiling without opening the camera or requiring camera
  permission.
- Power and battery runtime state.
- Network capability snapshots and real-time network capability updates on
  Android and iOS.
- App-level network speed stream based on this app UID traffic.
- Full NativeLens report aggregation.
- Offline compatibility summary using simple Dart rules.

## Installation

Add NativeLens to your `pubspec.yaml`:

```yaml
dependencies:
  native_lens: ^0.14.0
```

Then run:

```sh
flutter pub get
```

## Native Splash Setup Preview

NativeLens includes an early setup command for native splash screen
configuration. Start with a dry run:

```sh
dart run native_lens:splash --dry-run
```

Add this preview config to your app `pubspec.yaml`:

```yaml
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: true
```

The dry run validates the config, checks that the splash image exists, detects
Android and iOS project folders, and prints the native files that would be
created, modified, or backed up.

Android and iOS generation are available now:

```sh
dart run native_lens:splash --android
dart run native_lens:splash --ios
```

Before native files are changed, NativeLens creates a backup under:

```text
.native_lens_backup/splash/<timestamp>/
```

If generation fails mid-run, NativeLens restores the files from the current
backup automatically. iOS generation updates the static launch screen storyboard
and writes a `NativeLensSplash.imageset` asset catalog entry; the LaunchScreen
stays static and launch-screen safe.

## Platform Support

| Capability | Android | iOS | Notes |
| --- | --- | --- | --- |
| Platform summary | Native support | Native baseline | iOS includes safe OS, model, simulator/device, memory, processor, and thermal fields. Android-specific SDK/release fields remain Android-first. |
| Display info | Native support | Native baseline | iOS includes logical points, native pixels, scale, brightness, and current refresh rate. HDR type discovery remains Android-only. |
| Power/battery state | Native support | Native baseline | iOS includes battery level/state, charging/full status, Low Power Mode, battery monitoring availability, and thermal state. Android-only optimization and health/temperature fields fall back safely on iOS. |
| Network capability | Native support | Native baseline | iOS includes reachability, interface type, expensive/constrained status, and live updates. Android-only VPN, Bluetooth, low-latency, and high-bandwidth flags fall back safely on iOS. |
| System features | Android PackageManager | Safe fallback | iOS returns an empty list because there is no equivalent PackageManager feature matrix. |
| Sensors | Android SensorManager | Safe fallback | iOS returns an empty list in the current API rather than exposing partial or permission-sensitive sensor data. |
| Media codecs | Android MediaCodecList | Safe fallback | iOS returns an empty list; codec inventory is not exposed as a deep iOS capability module yet. |
| Camera capabilities | Android Camera2 metadata | Safe fallback | iOS returns an empty list and does not request camera permission or open the camera. |
| Theme mode | Native support | Native support | Reports light, dark, or unknown and supports live updates. |
| Device orientation | Native support | Native support | Snapshot and stream APIs are available on both mobile platforms. |
| App traffic speed | Android TrafficStats | Safe fallback | iOS currently reports unsupported/zero samples. This is not a full internet speed test. |
| Stream URL probe / HLS manifest probe | Dart support | Dart support | URL and manifest readiness checks run in Dart. They do not validate DRM, CDN correctness, player setup, or end-to-end playback. |

### iOS Capability Baseline

The iOS baseline is intentionally conservative. It improves these existing APIs:

- `getPlatformSummary()` reports `platformName`, `osName`, `osVersion`,
  `localizedModel`, simulator/device environment, physical memory, processor
  counts, thermal state, and `isIosNative`.
- `getDisplayInfo()` reports logical screen size in points, native pixel size,
  scale, native scale, brightness, current refresh rate, and `isIosNative`.
- `getPowerState()` and `watchPowerState()` report battery level when available,
  battery state, charging/full status, battery monitoring availability, Low
  Power Mode, thermal state, and `isIosNative`.
- `getNetworkCapability()` and `networkCapabilityStream` report connection
  status, interface type, expensive network status, constrained network status,
  and `isIosNative`.

Unsupported Android-only fields return safe values such as `null`, `false`,
`0`, `Unknown`, or an empty list. NativeLens does not request permissions for
these iOS baseline fields.

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

### Smart Feature Intelligence

NativeLens can analyze common feature flows without requiring developers to
manually build `NativeLensTaskRequirements`. Select a `NativeLensFeature`, and
NativeLens builds the underlying requirements internally before reusing the
same custom task rule engine.

```dart
final result = await NativeLens().analyzeFeature(
  NativeLensFeature.faceFilterCamera,
);
```

For more specific feature intent, pass `NativeLensFeatureOptions`.

```dart
final result = await NativeLens().analyzeFeature(
  NativeLensFeature.liveStreaming,
  options: const NativeLensFeatureOptions(
    realtime: true,
    highPerformance: true,
    minBatteryLevel: 25,
    preferUnmeteredNetwork: true,
    disallowPowerSaveMode: true,
  ),
);
```

Available smart features:

- `liveStreaming`
- `videoUpload`
- `faceFilterCamera`
- `cameraRecording`
- `backgroundSync`
- `arExperience`
- `stepTracking`
- `compassNavigation`
- `mediaProcessing`

Existing APIs remain supported. Use `analyzeCustomTask()` when you need full
manual control over requirements, and use `analyzePresetTask()` if you already
depend on preset feature preflight checks.

### Streaming Readiness Intelligence

NativeLens can check current device/network readiness before starting a
streaming feature. Use `analyzeStreamingReadiness()` when you want a focused
preflight signal for video playback, live streaming, or adaptive streaming
without adding a new `NativeLensFeature` enum value.

For stricter streaming intent, pass `NativeLensFeatureOptions`.

```dart
final result = await NativeLens().analyzeStreamingReadiness(
  options: const NativeLensFeatureOptions(
    realtime: true,
    preferUnmeteredNetwork: true,
    disallowPowerSaveMode: true,
  ),
);

if (result.riskLevel == 'low') {
  // Start playback normally
} else if (result.canContinue) {
  // Warn user or reduce quality
} else {
  // Show fallback
}
```

Streaming readiness checks device and network signals such as stable network,
media codec availability, battery level, display refresh rate, metered network
risk, and power saver mode. The result is a readiness signal, not a playback
guarantee.

NativeLens does not validate a specific HLS URL, CDN, DRM license, ExoPlayer
instance, AVPlayer item, or end-to-end playback pipeline.

### Stream URL Probe Intelligence

`analyzeStreamingReadiness()` checks current device/network readiness.
`probeStreamingUrl()` checks URL/manifest readiness for a specific stream URL.

Use `probeStreamingUrl()` when you want to know whether a stream URL is
reachable and appears to contain a readable HLS manifest before playback
startup.

```dart
final result = await NativeLens().probeStreamingUrl(
  url: 'https://example.com/stream.m3u8',
  options: const NativeLensStreamProbeOptions(
    timeout: Duration(seconds: 8),
    followRedirects: true,
    requireHttps: true,
  ),
);

if (result.riskLevel == 'low') {
  // Try playback startup normally
} else if (result.canContinue) {
  // Warn user or use fallback quality
} else {
  // Show fallback
}
```

The probe can report URL validation, HTTP status, final URL after redirects,
content type hints, manifest readability, likely HLS signals, and extracted
variant or segment URL counts.

This does not validate DRM, CDN correctness, ExoPlayer, AVPlayer, decoder
initialization, segment playback, or the full playback pipeline.

### Custom Task Requirements

NativeLens can analyze whether a device is ready for a developer-defined custom
feature or task.

```dart
final result = await NativeLens().analyzeCustomTask(
  taskName: 'Face Filter Camera',
  requirements: const NativeLensTaskRequirements(
    requiresCamera: true,
    requiresMicrophone: false,
    requiresStableNetwork: true,
    requiredSensors: ['gyroscope', 'accelerometer'],
    minBatteryLevel: 20,
  ),
);
```

The result includes:

- `riskLevel`
- `severity`
- `canContinue`
- `missingCapabilities`
- `recommendations`
- `userMessage`
- `developerMessage`

### Preset Feature Preflight

Developers can use ready-made preset checks for common feature flows without
manually building `NativeLensTaskRequirements`.

```dart
final result = await NativeLens().analyzePresetTask(
  NativeLensPreset.liveStreaming,
);

print(result.riskLevel);
print(result.canContinue);
print(result.userMessage);
print(result.recommendations);
```

Available presets:

- `liveStreaming`
- `videoUpload`
- `faceFilterCamera`
- `cameraRecording`
- `backgroundSync`
- `arExperience`
- `stepTracking`
- `compassNavigation`
- `mediaProcessing`

Presets reuse the same Custom Task Requirements engine internally.

### Theme Mode Intelligence

NativeLens can read the native system theme mode and listen for changes when an
app wants to sync its theme with the device.

```dart
final themeMode = await NativeLens().getThemeMode();

print(themeMode);
```

Use the live stream to react when the user changes the system theme:

```dart
NativeLens().watchThemeMode().listen((themeMode) {
  print(themeMode);
});
```

Possible values are:

- `NativeLensThemeMode.light`
- `NativeLensThemeMode.dark`
- `NativeLensThemeMode.unknown`

`unknown` is returned as a safe fallback when the platform cannot determine the
active native theme mode.

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

### Live Power State Stream

Receive event-driven battery and power updates from native platform listeners:

```dart
StreamBuilder<PowerState>(
  stream: NativeLens().watchPowerState(),
  builder: (context, snapshot) {
    final PowerState? powerState = snapshot.data;

    return Text('${powerState?.batteryLevel ?? 0}%');
  },
);
```

`watchPowerState()` uses Android battery broadcasts and iOS battery
notifications so apps can update battery and charging UI as native power state
events arrive.

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

Get the current device orientation snapshot from the native platform:

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
- Device name.
- Contacts.
- Photos.
- Location.
- Device-wide network usage statistics.
- SSID, BSSID, IP address, MAC address, or carrier name.

Network speed samples are based on this app UID traffic only.

The iOS platform, display, power, and network baselines use privacy-safe system
APIs and do not request permissions.

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

- Deep Android capability modules remain broader than iOS modules.
- iOS support is currently focused on privacy-safe baseline fields and
  safe-fallback behavior for unsupported deep capability modules.
- No macOS, Windows, Linux, or web implementation yet.

## Author

- Portfolio: https://bynahin.com/
- Pub.dev: https://pub.dev/packages/native_lens

## Articles & Announcements

Want to know why NativeLens was built?

- 📖 Medium article: NativeLens — A Flutter Package for Device Capability Intelligence Before Your Feature Fails  
  https://medium.com/@nahin.cdr/nativelens-a-flutter-package-for-device-capability-intelligence-before-your-feature-fails-8d7a2c086c91

## Repository

- Homepage: https://github.com/Nahin-CDR/native_lens
- Repository: https://github.com/Nahin-CDR/native_lens
- Issues: https://github.com/Nahin-CDR/native_lens/issues
