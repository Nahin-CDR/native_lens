## Unreleased

- Added event-driven `watchPowerState()` stream for live battery and power updates.
- Updated the example dashboard to use the live power state stream.

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
