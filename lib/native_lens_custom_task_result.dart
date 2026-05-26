/// Device readiness result for a developer-defined NativeLens task.
class NativeLensCustomTaskResult {
  /// Creates a custom task readiness result.
  const NativeLensCustomTaskResult({
    required this.taskName,
    required this.riskLevel,
    required this.severity,
    required this.canContinue,
    required this.reasons,
    required this.recommendations,
    required this.userMessage,
    required this.developerMessage,
    required this.analyzedAtMillis,
    this.requiredCapabilities = const <String>[],
    this.missingCapabilities = const <String>[],
    this.availableCapabilities = const <String>[],
  });

  /// Developer-defined task name.
  final String taskName;

  /// Current risk level. Expected values are `low`, `medium`, and `high`.
  final String riskLevel;

  /// User-facing severity. Expected values are `info`, `warning`, and `critical`.
  final String severity;

  /// Whether the task can continue under current device conditions.
  final bool canContinue;

  /// Capabilities required by the custom task.
  final List<String> requiredCapabilities;

  /// Required or preferred capabilities that are unavailable or unstable.
  final List<String> missingCapabilities;

  /// Required or preferred capabilities currently available on the device.
  final List<String> availableCapabilities;

  /// Human-readable reasons for the readiness result.
  final List<String> reasons;

  /// Suggested developer or product actions for the readiness result.
  final List<String> recommendations;

  /// Short message suitable for showing to an app user.
  final String userMessage;

  /// Diagnostic message suitable for logs or developer tooling.
  final String developerMessage;

  /// Analysis timestamp in milliseconds since epoch.
  final int analyzedAtMillis;

  /// Creates a custom task result from a map using stable field names.
  factory NativeLensCustomTaskResult.fromMap(Map<Object?, Object?> map) {
    return NativeLensCustomTaskResult(
      taskName: _readString(map, 'taskName'),
      riskLevel: _readString(map, 'riskLevel'),
      severity: _readString(map, 'severity'),
      canContinue: _readBool(map, 'canContinue'),
      reasons: _readStringList(map, 'reasons'),
      recommendations: _readStringList(map, 'recommendations'),
      userMessage: _readString(map, 'userMessage'),
      developerMessage: _readString(map, 'developerMessage'),
      analyzedAtMillis: _readInt(map, 'analyzedAtMillis'),
      requiredCapabilities: _readStringList(map, 'requiredCapabilities'),
      missingCapabilities: _readStringList(map, 'missingCapabilities'),
      availableCapabilities: _readStringList(map, 'availableCapabilities'),
    );
  }

  /// Serializes the result to a map using stable field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'taskName': taskName,
      'riskLevel': riskLevel,
      'severity': severity,
      'canContinue': canContinue,
      'requiredCapabilities': requiredCapabilities,
      'missingCapabilities': missingCapabilities,
      'availableCapabilities': availableCapabilities,
      'reasons': reasons,
      'recommendations': recommendations,
      'userMessage': userMessage,
      'developerMessage': developerMessage,
      'analyzedAtMillis': analyzedAtMillis,
    };
  }

  @override
  String toString() {
    return 'NativeLensCustomTaskResult('
        'taskName: $taskName, '
        'riskLevel: $riskLevel, '
        'severity: $severity, '
        'canContinue: $canContinue, '
        'requiredCapabilities: $requiredCapabilities, '
        'missingCapabilities: $missingCapabilities, '
        'availableCapabilities: $availableCapabilities, '
        'reasons: $reasons, '
        'recommendations: $recommendations, '
        'userMessage: $userMessage, '
        'developerMessage: $developerMessage, '
        'analyzedAtMillis: $analyzedAtMillis'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static List<String> _readStringList(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is! List<Object?>) {
      return <String>[];
    }

    final List<String> values = <String>[];
    for (final Object? item in value) {
      if (item is String && item.isNotEmpty) {
        values.add(item);
      }
    }
    return values;
  }
}
