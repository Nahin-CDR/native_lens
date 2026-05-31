import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'camera_capability.dart';
import 'device_orientation_info.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_method_channel.dart';
import 'native_sensor.dart';
import 'native_lens_theme_mode.dart';
import 'network_capability.dart';
import 'network_speed_sample.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';

/// The platform interface for NativeLens implementations.
abstract class NativeLensPlatform extends PlatformInterface {
  /// Constructs a NativeLensPlatform.
  NativeLensPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeLensPlatform _instance = MethodChannelNativeLens();

  /// The default instance of [NativeLensPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeLens].
  static NativeLensPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeLensPlatform] when
  /// they register themselves.
  static set instance(NativeLensPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns a summary of the Android platform running the app.
  Future<PlatformSummary> getPlatformSummary() {
    throw UnimplementedError('getPlatformSummary() has not been implemented.');
  }

  /// Returns the native Android system features reported by the device.
  Future<List<SystemFeature>> getSystemFeatures() {
    throw UnimplementedError('getSystemFeatures() has not been implemented.');
  }

  /// Returns the native Android sensors reported by the device.
  Future<List<NativeSensor>> getSensors() {
    throw UnimplementedError('getSensors() has not been implemented.');
  }

  /// Returns native Android display capabilities for the active display.
  Future<DisplayInfo> getDisplayInfo() {
    throw UnimplementedError('getDisplayInfo() has not been implemented.');
  }

  /// Returns native Android media codec capabilities reported by the device.
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    throw UnimplementedError('getMediaCodecs() has not been implemented.');
  }

  /// Returns native Android Camera2 capabilities reported by the device.
  Future<List<CameraCapability>> getCameraCapabilities() {
    throw UnimplementedError(
      'getCameraCapabilities() has not been implemented.',
    );
  }

  /// Returns native Android battery and power runtime state.
  Future<PowerState> getPowerState() {
    throw UnimplementedError('getPowerState() has not been implemented.');
  }

  /// Emits native battery and power state updates as the platform reports them.
  Stream<PowerState> watchPowerState() {
    throw UnimplementedError('watchPowerState() has not been implemented.');
  }

  /// Returns the native system theme mode reported by the platform.
  Future<NativeLensThemeMode> getThemeMode() {
    throw UnimplementedError('getThemeMode() has not been implemented.');
  }

  /// Emits native system theme mode updates as the platform reports them.
  Stream<NativeLensThemeMode> watchThemeMode() {
    throw UnimplementedError('watchThemeMode() has not been implemented.');
  }

  /// Returns native Android network capability information for the active network.
  Future<NetworkCapability> getNetworkCapability() {
    throw UnimplementedError(
      'getNetworkCapability() has not been implemented.',
    );
  }

  /// Emits native Android network capability updates as the active network changes.
  ///
  /// This stream listens to Android network callbacks so Wi-Fi, mobile data,
  /// VPN, and flight mode changes can update the app without a manual refresh.
  Stream<NetworkCapability> get networkCapabilityStream {
    throw UnimplementedError(
      'networkCapabilityStream has not been implemented.',
    );
  }

  /// Emits app-level upload and download speed samples once per second.
  ///
  /// This measures this app's Android UID traffic, not full device internet
  /// speed and not device-wide network usage.
  Stream<NetworkSpeedSample> get networkSpeedStream {
    throw UnimplementedError('networkSpeedStream has not been implemented.');
  }

  /// Returns the current device orientation from the Android display.
  Future<DeviceOrientationInfo> getDeviceOrientation() {
    throw UnimplementedError(
      'getDeviceOrientation() has not been implemented.',
    );
  }

  /// Emits device orientation updates as the device rotates.
  Stream<DeviceOrientationInfo> get deviceOrientationStream {
    throw UnimplementedError(
      'deviceOrientationStream has not been implemented.',
    );
  }
}
