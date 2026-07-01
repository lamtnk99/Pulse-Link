import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/core/utils/blood_compatibility.dart';

void main() {
  group('BloodCompatibility', () {
    test('allows O+ donor for positive recipient blood groups', () {
      expect(
        BloodCompatibility.canDonateTo(
          donorBloodType: 'O+',
          recipientBloodType: 'O+',
        ),
        isTrue,
      );
      expect(
        BloodCompatibility.canDonateTo(
          donorBloodType: 'O+',
          recipientBloodType: 'AB+',
        ),
        isTrue,
      );
    });

    test('blocks incompatible donation', () {
      expect(
        BloodCompatibility.canDonateTo(
          donorBloodType: 'A+',
          recipientBloodType: 'O+',
        ),
        isFalse,
      );
    });
  });
}
