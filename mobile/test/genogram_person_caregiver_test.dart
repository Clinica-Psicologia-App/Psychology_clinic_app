import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';

Map<String, dynamic> _base(String? caregiver) => {
      'id': 'p',
      'clinic_id': 'c',
      'patient_id': 'pat',
      'full_name': 'Fulano',
      'is_deceased': false,
      'is_sensitive': false,
      'caregiver_role': caregiver,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };

void main() {
  test('fromJson lê caregiver_role e expõe os papéis de cuidado', () {
    final principal = GenogramPerson.fromJson(_base('important'));
    expect(principal.caregiverRole, 'important');
    expect(principal.isPrimaryCaregiver, isTrue);
    expect(principal.isPartialCaregiver, isFalse);

    final parcial = GenogramPerson.fromJson(_base('partial'));
    expect(parcial.isPartialCaregiver, isTrue);
    expect(parcial.isPrimaryCaregiver, isFalse);

    final nenhum = GenogramPerson.fromJson(_base(null));
    expect(nenhum.caregiverRole, isNull);
    expect(nenhum.isPrimaryCaregiver, isFalse);
    expect(nenhum.isPartialCaregiver, isFalse);
  });
}
