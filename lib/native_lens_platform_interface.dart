import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_method_channel.dart';
import 'native_sensor.dart';
import 'platform_summary.dart';
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
}
