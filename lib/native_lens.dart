import 'display_info.dart';
import 'native_lens_platform_interface.dart';
import 'native_sensor.dart';
import 'platform_summary.dart';
import 'system_feature.dart';

export 'display_info.dart';
export 'native_sensor.dart';
export 'platform_summary.dart';
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
}
