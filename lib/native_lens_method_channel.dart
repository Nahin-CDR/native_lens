import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'display_info.dart';
import 'native_lens_platform_interface.dart';
import 'native_sensor.dart';
import 'platform_summary.dart';
import 'system_feature.dart';

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

  @override
  Future<List<SystemFeature>> getSystemFeatures() async {
    final List<Object?>? featureList = await methodChannel
        .invokeListMethod<Object?>('getSystemFeatures');

    if (featureList == null) {
      throw PlatformException(
        code: 'native_lens_empty_features',
        message: 'Android returned an empty system feature list.',
      );
    }

    final List<SystemFeature> features = <SystemFeature>[];

    for (final Object? featureItem in featureList) {
      if (featureItem is Map<Object?, Object?>) {
        features.add(SystemFeature.fromMap(featureItem));
      }
    }

    return features;
  }

  @override
  Future<List<NativeSensor>> getSensors() async {
    final List<Object?>? sensorList = await methodChannel
        .invokeListMethod<Object?>('getSensors');

    if (sensorList == null) {
      throw PlatformException(
        code: 'native_lens_empty_sensors',
        message: 'Android returned an empty sensor list.',
      );
    }

    final List<NativeSensor> sensors = <NativeSensor>[];

    for (final Object? sensorItem in sensorList) {
      if (sensorItem is Map<Object?, Object?>) {
        sensors.add(NativeSensor.fromMap(sensorItem));
      }
    }

    return sensors;
  }

  @override
  Future<DisplayInfo> getDisplayInfo() async {
    final Map<Object?, Object?>? displayMap = await methodChannel
        .invokeMapMethod<Object?, Object?>('getDisplayInfo');

    if (displayMap == null) {
      throw PlatformException(
        code: 'native_lens_empty_display',
        message: 'Android returned empty display information.',
      );
    }

    return DisplayInfo.fromMap(displayMap);
  }
}
