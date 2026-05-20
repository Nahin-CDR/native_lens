import 'native_lens_platform_interface.dart';
import 'platform_summary.dart';

export 'platform_summary.dart';

/// Entry point for reading basic native Android information.
class NativeLens {
  /// Returns a summary of the Android platform running the app.
  Future<PlatformSummary> getPlatformSummary() {
    return NativeLensPlatform.instance.getPlatformSummary();
  }
}
