import 'native_lens_task.dart';

/// Offline risk analysis result for a NativeLens task.
class NativeTaskRiskResult {
  /// Creates a NativeLens task risk result.
  const NativeTaskRiskResult({
    required this.task,
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
    required this.recommendation,
    required this.analyzedAtMillis,
  });

  /// Task that was analyzed.
  final NativeLensTask task;

  /// Current risk level. Expected values are `low`, `medium`, and `high`.
  final String riskLevel;

  /// Confidence from 0.0 to 1.0.
  final double confidence;

  /// Human-readable reasons for the risk level.
  final List<String> reasons;

  /// Simple task-aware recommendation.
  final String recommendation;

  /// Analysis timestamp in milliseconds since epoch.
  final int analyzedAtMillis;

  /// Serializes the result to a map using stable field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'task': task.name,
      'riskLevel': riskLevel,
      'confidence': confidence,
      'reasons': reasons,
      'recommendation': recommendation,
      'analyzedAtMillis': analyzedAtMillis,
    };
  }

  @override
  String toString() {
    return 'NativeTaskRiskResult('
        'task: ${task.name}, '
        'riskLevel: $riskLevel, '
        'confidence: $confidence, '
        'reasons: $reasons, '
        'recommendation: $recommendation, '
        'analyzedAtMillis: $analyzedAtMillis'
        ')';
  }
}
