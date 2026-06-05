import '../native_lens_feature_options.dart';
import '../native_lens_task_requirements.dart';

/// Internal requirements mapping for streaming readiness preflight.
NativeLensTaskRequirements nativeLensStreamingReadinessRequirements(
  NativeLensFeatureOptions options,
) {
  final int minBatteryLevel = _stricterInt(15, _optionMinBatteryLevel(options));
  final double minRefreshRate = _stricterDouble(
    30,
    _optionMinRefreshRate(options),
  );

  return NativeLensTaskRequirements(
    requiresStableNetwork: true,
    requiresUnmeteredNetwork: options.preferUnmeteredNetwork,
    requiresMediaCodecs: true,
    minBatteryLevel: minBatteryLevel,
    minRefreshRate: minRefreshRate,
    allowPowerSaveMode: false,
  );
}

int _optionMinBatteryLevel(NativeLensFeatureOptions options) {
  int minBatteryLevel = options.minBatteryLevel ?? 0;

  if (options.realtime) {
    minBatteryLevel = _stricterInt(minBatteryLevel, 20);
  }

  if (options.highPerformance) {
    minBatteryLevel = _stricterInt(minBatteryLevel, 25);
  }

  return minBatteryLevel;
}

double _optionMinRefreshRate(NativeLensFeatureOptions options) {
  if (options.realtime || options.highPerformance) {
    return 60;
  }

  return 0;
}

int _stricterInt(int currentValue, int candidateValue) {
  return currentValue > candidateValue ? currentValue : candidateValue;
}

double _stricterDouble(double currentValue, double candidateValue) {
  return currentValue > candidateValue ? currentValue : candidateValue;
}
