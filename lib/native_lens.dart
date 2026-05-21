import 'camera_capability.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_platform_interface.dart';
import 'native_lens_report.dart';
import 'native_sensor.dart';
import 'network_capability.dart';
import 'network_speed_sample.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';

export 'camera_capability.dart';
export 'display_info.dart';
export 'media_codec_capability.dart';
export 'native_sensor.dart';
export 'native_lens_report.dart';
export 'network_capability.dart';
export 'network_speed_sample.dart';
export 'platform_summary.dart';
export 'power_state.dart';
export 'system_feature.dart';

/// Entry point for reading basic native Android information.
class NativeLens {
  /// Returns a summary of the Android platform running the app.
  Future<PlatformSummary> getPlatformSummary() {
    return NativeLensPlatform.instance.getPlatformSummary();
  }

  /// Returns the native Android system features reported by the device.
  Future<List<SystemFeature>> getSystemFeatures() {
    return NativeLensPlatform.instance.getSystemFeatures();
  }

  /// Returns the native Android sensors reported by the device.
  Future<List<NativeSensor>> getSensors() {
    return NativeLensPlatform.instance.getSensors();
  }

  /// Returns native Android display capabilities for the active display.
  Future<DisplayInfo> getDisplayInfo() {
    return NativeLensPlatform.instance.getDisplayInfo();
  }

  /// Returns native Android media codec capabilities reported by the device.
  Future<List<MediaCodecCapability>> getMediaCodecs() {
    return NativeLensPlatform.instance.getMediaCodecs();
  }

  /// Returns native Android Camera2 capabilities reported by the device.
  Future<List<CameraCapability>> getCameraCapabilities() {
    return NativeLensPlatform.instance.getCameraCapabilities();
  }

  /// Returns native Android battery and power runtime state.
  Future<PowerState> getPowerState() {
    return NativeLensPlatform.instance.getPowerState();
  }

  /// Returns native Android network capability information for the active network.
  Future<NetworkCapability> getNetworkCapability() {
    return NativeLensPlatform.instance.getNetworkCapability();
  }

  /// Generates a complete snapshot report from the existing NativeLens APIs.
  ///
  /// This method does not call any new native Android API. It collects the
  /// current platform, feature, sensor, display, media, camera, power, and
  /// network snapshots into one readable [NativeLensReport].
  Future<NativeLensReport> generateReport() async {
    final PlatformSummary platformSummary = await getPlatformSummary();
    final List<SystemFeature> systemFeatures = await getSystemFeatures();
    final List<NativeSensor> sensors = await getSensors();
    final DisplayInfo displayInfo = await getDisplayInfo();
    final List<MediaCodecCapability> mediaCodecs = await getMediaCodecs();
    final List<CameraCapability> cameraCapabilities =
        await getCameraCapabilities();
    final PowerState powerState = await getPowerState();
    final NetworkCapability networkCapability = await getNetworkCapability();

    return NativeLensReport(
      platformSummary: platformSummary,
      systemFeatures: systemFeatures,
      sensors: sensors,
      displayInfo: displayInfo,
      mediaCodecs: mediaCodecs,
      cameraCapabilities: cameraCapabilities,
      powerState: powerState,
      networkCapability: networkCapability,
      generatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Emits native Android network capability updates as the active network changes.
  ///
  /// This stream listens to Android network callbacks so Wi-Fi, mobile data,
  /// VPN, and flight mode changes can update the app without a manual refresh.
  Stream<NetworkCapability> get networkCapabilityStream {
    return NativeLensPlatform.instance.networkCapabilityStream;
  }

  /// Emits app-level upload and download speed samples once per second.
  ///
  /// This measures this app's Android UID traffic, not full device internet
  /// speed and not device-wide network usage.
  Stream<NetworkSpeedSample> get networkSpeedStream {
    return NativeLensPlatform.instance.networkSpeedStream;
  }
}
