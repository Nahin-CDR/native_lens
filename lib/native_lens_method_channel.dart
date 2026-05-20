import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_lens_platform_interface.dart';
import 'platform_summary.dart';

/// An implementation of [NativeLensPlatform] that uses method channels.
class MethodChannelNativeLens extends NativeLensPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_lens');

  @override
  Future<PlatformSummary> getPlatformSummary() async {
    final Map<Object?, Object?>? summaryMap = await methodChannel
        .invokeMapMethod<Object?, Object?>('getPlatformSummary');

    if (summaryMap == null) {
      throw PlatformException(
        code: 'native_lens_empty_summary',
        message: 'Android returned an empty platform summary.',
      );
    }

    return PlatformSummary.fromMap(summaryMap);
  }
}
