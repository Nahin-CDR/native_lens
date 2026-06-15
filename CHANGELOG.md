## Unreleased

- Added HLS manifest classification for master, media, and unknown playlists.

## 0.14.0

Release date: 2026-06-11

- Added README support matrix for Android and iOS capability coverage,
  fallback behavior, and privacy-safe iOS baseline fields.
- Improved iOS network capability baseline with safe interface type,
  expensive/constrained network, and iOS-native marker fields.
- Improved iOS power capability baseline with safe battery state, monitoring,
  low power mode, thermal state, and iOS-native marker fields.
- Improved iOS display capability baseline with safe logical size, native
  pixel size, scale, brightness, and iOS-native marker fields.
- Improved iOS platform summary baseline with safe native OS, model, runtime,
  memory, processor, thermal state, and iOS-native marker fields.

## 0.13.0

- Added Stream URL Probe Intelligence.
- Added stream probe models for URL and manifest readiness results.
- Added internal HLS manifest parser.
- Added `probeStreamingUrl()`.
- Added Stream URL Probe Intelligence section to the example app.
- Added README guide for URL/manifest readiness probing.

## 0.12.0

- Added Streaming Readiness Intelligence.
- Added `analyzeStreamingReadiness()`.
- Added device/network readiness check for streaming preflight.
- Added Streaming Readiness Intelligence section to the example app.

## 0.11.0

- Added Smart Feature Intelligence.
- Added `analyzeFeature()`.
- Added `NativeLensFeature`.
- Added `NativeLensFeatureOptions`.
- Added internal smart feature requirement mapping.
- Added Smart Feature Intelligence section to the example app.

## 0.10.0

- Added native theme mode detection.
- Added real-time theme mode stream.
- Added Android and iOS support for theme mode intelligence.
- Added example app Theme Mode Intelligence section.

## 0.9.0

- Added `NativeLensPreset` enum.
- Added preset task mappings.
- Added `analyzePresetTask()`.
- Added preset feature preflight support.
- Added presets:
  - `liveStreaming`
  - `videoUpload`
  - `faceFilterCamera`
  - `cameraRecording`
  - `backgroundSync`
  - `arExperience`
  - `stepTracking`
  - `compassNavigation`
  - `mediaProcessing`
- Added example app preset selector.
- Added README guide for Preset Feature Preflight.

## 0.8.1

- Added Articles & Announcements links to README.
- Added Medium article link.
- Added LinkedIn launch post link.

## 0.8.0

- Added Custom Task Requirements API.
- Added `NativeLensTaskRequirements` model.
- Added `NativeLensCustomTaskResult` model.
- Added `analyzeCustomTask()`.
- Added rule-based checks for camera, microphone, network, battery, sensors,
  system features, media codecs, HEVC, counts, refresh rate, and power saver.
- Added example app custom task demo.
- Added README guide for custom task requirements.

## 0.7.0

Release date: 2026-05-26

- Added Native Splash Setup Tool.
- Added command: `dart run native_lens:splash`.
- Added `pubspec.yaml` based splash config.
- Added `--dry-run` preview mode.
- Added Android native splash generation.
- Added Android 12+ splash support.
- Added iOS LaunchScreen generation.
- Added backup manifest and rollback support.
- Added validation for image path and background color.
- Added `args` and `yaml` dependencies for CLI parsing and pubspec parsing.

## 0.6.0

Release date: 2026-05-26

- Added `watchPowerState()`.
- Added event-driven live `PowerState` stream.
- Added Android `BroadcastReceiver` support for battery and power saver changes.
- Added iOS `UIDevice` battery and low power mode notification support.
- Updated the example app to use the live power stream instead of timer polling.
- Kept the `getPowerState()` snapshot API unchanged.
- Added no new dependencies.

## 0.5.0

Release date: 2026-05-26

- Added offline Task Risk Analysis API
- Added NativeLensTask enum
- Added NativeTaskRiskResult model
- Added smart rule-based task risk engine
- Added capability requirement detection
- Added required/available/missing capabilities in task risk result
- Added AR, step tracking, and compass navigation task support
- Added task risk and capability UI in example dashboard
- Added ML workspace, dataset validation, training, prediction, and evaluation scripts
- Added real device dataset collection guide
- Added ML model deployment strategy documentation

## 0.4.0

Release date: 2026-05-24

- Added NativeLensDatasetRow model
- Added generateDatasetRow() API
- Added NativeLensDatasetExporter for JSON/CSV export
- Added Dataset Export actions in example dashboard
- Added built-in visual charts to example dashboard

## 0.3.0

Release date: 2026-05-23

- Added initial iOS foundation support using Swift Platform Channels
- Added iOS platform summary support
- Added iOS power/battery safe support
- Added iOS network capability snapshot and stream support
- Added iOS device orientation snapshot and stream support
- Added safe iOS fallbacks for unsupported deep capability modules
- Added iOS example project support
- Added iOS CocoaPods podspec

## 0.2.1

Release date: 2026-05-23

- Updated package homepage to personal portfolio website
- Added author/portfolio link to README

## 0.2.0

Release date: 2026-05-23

- Added Screen Debug Trace utility
- Added native device orientation snapshot API
- Added native device orientation live stream
- Improved example app into a professional diagnostics dashboard
- Fixed Android orientation build issue by using Surface rotation constants

## 0.1.0

Initial pre-release for Android.

- Added Android platform summary API.
- Added system feature matrix.
- Added sensor capability profiler.
- Added display capability profiler.
- Added media codec capability profiler.
- Added Camera2 capability profiler without requiring camera permission.
- Added power and battery runtime state.
- Added network capability profiler using `ACCESS_NETWORK_STATE`.
- Added real-time network capability and app traffic speed streams.
- Added full NativeLens report aggregation.
- Added offline compatibility summary analysis.
- Added example app sections for all current capability modules.
