class BloodJourney {
  const BloodJourney({
    required this.id,
    required this.destinationType,
    required this.currentStep,
    required this.steps,
    this.locationLabel,
    this.finalMessage,
    this.publishedAt,
    this.completedAt,
    this.verifyUrl,
  });

  factory BloodJourney.fromJson(Map<String, dynamic> json) {
    return BloodJourney(
      id: json['id'] as String,
      destinationType: json['destination_type'] as String? ?? 'patient',
      currentStep: json['current_step'] as String? ?? 'received',
      locationLabel: json['location_label'] as String?,
      finalMessage: json['final_message'] as String?,
      publishedAt: _parseDate(json['published_at']),
      completedAt: _parseDate(json['completed_at']),
      verifyUrl: json['verify_url'] as String?,
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BloodJourneyStep.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String destinationType;
  final String currentStep;
  final String? locationLabel;
  final String? finalMessage;
  final DateTime? publishedAt;
  final DateTime? completedAt;
  final String? verifyUrl;
  final List<BloodJourneyStep> steps;
}

class BloodJourneyStep {
  const BloodJourneyStep({
    required this.key,
    required this.label,
    required this.completed,
    this.message,
    this.occurredAt,
  });

  factory BloodJourneyStep.fromJson(Map<String, dynamic> json) {
    return BloodJourneyStep(
      key: json['key'] as String,
      label: json['label'] as String,
      message: json['message'] as String?,
      occurredAt: _parseDate(json['occurred_at']),
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String key;
  final String label;
  final String? message;
  final DateTime? occurredAt;
  final bool completed;
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
