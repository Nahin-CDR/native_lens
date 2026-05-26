import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_capability.dart';
import 'device_orientation_info.dart';
import 'display_info.dart';
import 'media_codec_capability.dart';
import 'native_lens_platform_interface.dart';
import 'native_sensor.dart';
import 'network_capability.dart';
import 'network_speed_sample.dart';
import 'platform_summary.dart';
import 'power_state.dart';
import 'system_feature.dart';

/// An implementation of [NativeLensPlatform] that uses method channels.
class MethodChannelNativeLens extends NativeLensPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_lens');

  /// The event channel used to receive live app network speed samples.
  @visibleForTesting
  final networkSpeedEventChannel = const EventChannel(
    'native_lens/network_speed',
  );

  /// The event channel used to receive live Android network capability updates.
  @visibleForTesting
  final networkCapabilityEventChannel = const EventChannel(
    'native_lens/network_capability',
  );

  /// The event channel used to receive live device orientation updates.
  @visibleForTesting
  final deviceOrientationEventChannel = const EventChannel(
    'native_lens/device_orientation',
  );

  /// The event channel used to receive live power state updates.
  @visibleForTesting
  final powerStateEventChannel = const EventChannel('native_lens/power_state');

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

  @override
  Future<List<MediaCodecCapability>> getMediaCodecs() async {
    final List<Object?>? codecList = await methodChannel
        .invokeListMethod<Object?>('getMediaCodecs');

    if (codecList == null) {
      throw PlatformException(
        code: 'native_lens_empty_media_codecs',
        message: 'Android returned an empty media codec list.',
      );
    }

    final List<MediaCodecCapability> codecs = <MediaCodecCapability>[];

    for (final Object? codecItem in codecList) {
      if (codecItem is Map<Object?, Object?>) {
        codecs.add(MediaCodecCapability.fromMap(codecItem));
      }
    }

    return codecs;
  }

  @override
  Future<List<CameraCapability>> getCameraCapabilities() async {
    final List<Object?>? cameraList = await methodChannel
        .invokeListMethod<Object?>('getCameraCapabilities');

    if (cameraList == null) {
      throw PlatformException(
        code: 'native_lens_empty_camera_capabilities',
        message: 'Android returned an empty camera capability list.',
      );
    }

    final List<CameraCapability> cameras = <CameraCapability>[];

    for (final Object? cameraItem in cameraList) {
      if (cameraItem is Map<Object?, Object?>) {
        cameras.add(CameraCapability.fromMap(cameraItem));
      }
    }

    return cameras;
  }

  @override
  Future<PowerState> getPowerState() async {
    final Map<Object?, Object?>? powerMap = await methodChannel
        .invokeMapMethod<Object?, Object?>('getPowerState');

    if (powerMap == null) {
      throw PlatformException(
        code: 'native_lens_empty_power_state',
        message: 'Android returned empty power state information.',
      );
    }

    return PowerState.fromMap(powerMap);
  }

  @override
  Stream<PowerState> watchPowerState() {
    return powerStateEventChannel.receiveBroadcastStream().map((Object? event) {
      if (event is Map<Object?, Object?>) {
        return PowerState.fromMap(event);
      }

      return PowerState.fromMap(<Object?, Object?>{});
    });
  }

  @override
  Future<NetworkCapability> getNetworkCapability() async {
    final Map<Object?, Object?>? networkMap = await methodChannel
        .invokeMapMethod<Object?, Object?>('getNetworkCapability');

    if (networkMap == null) {
      throw PlatformException(
        code: 'native_lens_empty_network_capability',
        message: 'Android returned empty network capability information.',
      );
    }

    return NetworkCapability.fromMap(networkMap);
  }

  @override
  Stream<NetworkCapability> get networkCapabilityStream {
    return networkCapabilityEventChannel.receiveBroadcastStream().map((
      Object? event,
    ) {
      if (event is Map<Object?, Object?>) {
        return NetworkCapability.fromMap(event);
      }

      return NetworkCapability.fromMap(<Object?, Object?>{});
    });
  }

  @override
  Future<DeviceOrientationInfo> getDeviceOrientation() async {
    final Map<Object?, Object?>? orientationMap = await methodChannel
        .invokeMapMethod<Object?, Object?>('getDeviceOrientation');

    if (orientationMap == null) {
      throw PlatformException(
        code: 'native_lens_empty_device_orientation',
        message: 'Android returned empty device orientation information.',
      );
    }

    return DeviceOrientationInfo.fromMap(orientationMap);
  }

  @override
  Stream<DeviceOrientationInfo> get deviceOrientationStream {
    return deviceOrientationEventChannel.receiveBroadcastStream().map((
      Object? event,
    ) {
      if (event is Map<Object?, Object?>) {
        return DeviceOrientationInfo.fromMap(event);
      }

      return DeviceOrientationInfo.fromMap(<Object?, Object?>{});
    });
  }

  @override
  Stream<NetworkSpeedSample> get networkSpeedStream {
    return networkSpeedEventChannel.receiveBroadcastStream().map((
      Object? event,
    ) {
      if (event is Map<Object?, Object?>) {
        return NetworkSpeedSample.fromMap(event);
      }

      return NetworkSpeedSample.fromMap(<Object?, Object?>{});
    });
  }
}
