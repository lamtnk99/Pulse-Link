class BloodCompatibility {
  const BloodCompatibility._();

  static const Map<String, Set<String>> _canDonateTo = {
    'O-': {'O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'},
    'O+': {'O+', 'A+', 'B+', 'AB+'},
    'A-': {'A-', 'A+', 'AB-', 'AB+'},
    'A+': {'A+', 'AB+'},
    'B-': {'B-', 'B+', 'AB-', 'AB+'},
    'B+': {'B+', 'AB+'},
    'AB-': {'AB-', 'AB+'},
    'AB+': {'AB+'},
  };

  static bool canDonateTo({
    required String donorBloodType,
    required String recipientBloodType,
  }) {
    return _canDonateTo[donorBloodType]?.contains(recipientBloodType) ?? false;
  }
}
