/// Optional intent modifiers for NativeLens feature intelligence.
class NativeLensFeatureOptions {
  /// Creates feature analysis options.
  const NativeLensFeatureOptions({
    this.realtime = false,
    this.highPerformance = false,
    this.minBatteryLevel,
    this.preferUnmeteredNetwork = false,
    this.disallowPowerSaveMode = false,
  });

  /// Whether the feature is expected to run in realtime.
  final bool realtime;

  /// Whether the feature should prefer higher performance device conditions.
  final bool highPerformance;

  /// Minimum battery percentage preferred for the feature.
  final int? minBatteryLevel;

  /// Whether the feature should prefer an unmetered active network.
  final bool preferUnmeteredNetwork;

  /// Whether the feature should avoid running while power saver is enabled.
  final bool disallowPowerSaveMode;
}
