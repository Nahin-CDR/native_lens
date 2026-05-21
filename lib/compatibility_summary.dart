/// A readable offline compatibility summary for a NativeLens report.
class CompatibilitySummary {
  /// Creates a compatibility summary from simple rule-based analysis.
  const CompatibilitySummary({
    required this.overallScore,
    required this.overallLevel,
    required this.powerRiskLevel,
    required this.networkRiskLevel,
    required this.mediaCapabilityLevel,
    required this.cameraCapabilityLevel,
    required this.displayCapabilityLevel,
    required this.recommendations,
    required this.warnings,
    required this.generatedAtMillis,
  });

  /// Overall compatibility score from 0 to 100.
  final int overallScore;

  /// Readable overall level, such as Excellent, Good, Fair, or Limited.
  final String overallLevel;

  /// Readable power risk level.
  final String powerRiskLevel;

  /// Readable network risk level.
  final String networkRiskLevel;

  /// Readable media capability level.
  final String mediaCapabilityLevel;

  /// Readable camera capability level.
  final String cameraCapabilityLevel;

  /// Readable display capability level.
  final String displayCapabilityLevel;

  /// Friendly suggestions based on the device capabilities.
  final List<String> recommendations;

  /// Important limitations or runtime risks found in the report.
  final List<String> warnings;

  /// The time this summary was generated, in milliseconds since epoch.
  final int generatedAtMillis;

  /// Converts this compatibility summary to a map.
  Map<String, Object> toMap() {
    return <String, Object>{
      'overallScore': overallScore,
      'overallLevel': overallLevel,
      'powerRiskLevel': powerRiskLevel,
      'networkRiskLevel': networkRiskLevel,
      'mediaCapabilityLevel': mediaCapabilityLevel,
      'cameraCapabilityLevel': cameraCapabilityLevel,
      'displayCapabilityLevel': displayCapabilityLevel,
      'recommendations': recommendations,
      'warnings': warnings,
      'generatedAtMillis': generatedAtMillis,
    };
  }

  /// Returns a readable string with all compatibility summary fields.
  @override
  String toString() {
    return 'CompatibilitySummary('
        'overallScore: $overallScore, '
        'overallLevel: $overallLevel, '
        'powerRiskLevel: $powerRiskLevel, '
        'networkRiskLevel: $networkRiskLevel, '
        'mediaCapabilityLevel: $mediaCapabilityLevel, '
        'cameraCapabilityLevel: $cameraCapabilityLevel, '
        'displayCapabilityLevel: $displayCapabilityLevel, '
        'recommendations: $recommendations, '
        'warnings: $warnings, '
        'generatedAtMillis: $generatedAtMillis'
        ')';
  }
}
