import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/create_patient_request.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';

void main() {
  test('Patient.fromJson maps psychologist and status', () {
    final patient = Patient.fromJson({
      'id': 'p1',
      'full_name': 'Ana Silva',
      'email': 'ana@example.com',
      'phone': '+5511999990001',
      'profile_id': 'prof1',
      'responsible_psychologist_id': 'psych1',
      'responsible_psychologist': {'full_name': 'Dr. João'},
      'access_profile': {'is_active': true},
    });

    expect(patient.fullName, 'Ana Silva');
    expect(patient.responsiblePsychologistName, 'Dr. João');
    expect(patient.accessStatus, PatientAccessStatus.active);
  });

  test('CreatePatientRequest.toJson omits empty optional fields', () {
    final json = const CreatePatientRequest(
      email: 'novo@example.com',
      password: 'SenhaSegura1',
      fullName: 'Novo Paciente',
      responsiblePsychologistId: 'psych-uuid',
    ).toJson();

    expect(json['email'], 'novo@example.com');
    expect(json.containsKey('cpf'), isFalse);
    expect(json.containsKey('birth_date'), isFalse);
  });
}
