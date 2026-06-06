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
      'gender': 'Feminino',
      'relationship_status': 'Solteira',
      'education_level': 'Ensino superior completo',
      'occupation': 'Psicóloga',
      'country_birth': 'Brasil',
      'state_birth': 'Rio Grande do Sul',
      'religious_orientation': 'Sem religião',
      'ethnic_group': 'Branca',
      'sexual_orientation': 'Heterossexual',
      'has_children': true,
      'intake_summary': 'Síntese clínica inicial.',
      'current_life_context': 'Paciente em transição profissional.',
      'therapy_demands': 'Reduzir ansiedade e organizar rotina.',
      'profile_id': 'prof1',
      'responsible_psychologist_id': 'psych1',
      'responsible_psychologist': {'full_name': 'Dr. João'},
      'access_profile': {'is_active': true},
    });

    expect(patient.fullName, 'Ana Silva');
    expect(patient.responsiblePsychologistName, 'Dr. João');
    expect(patient.accessStatus, PatientAccessStatus.active);
    expect(patient.gender, 'Feminino');
    expect(patient.relationshipStatus, 'Solteira');
    expect(patient.educationLevel, 'Ensino superior completo');
    expect(patient.occupation, 'Psicóloga');
    expect(patient.countryBirth, 'Brasil');
    expect(patient.stateBirth, 'Rio Grande do Sul');
    expect(patient.religiousOrientation, 'Sem religião');
    expect(patient.ethnicGroup, 'Branca');
    expect(patient.sexualOrientation, 'Heterossexual');
    expect(patient.hasChildren, isTrue);
    expect(patient.intakeSummary, 'Síntese clínica inicial.');
    expect(
      patient.currentLifeContext,
      'Paciente em transição profissional.',
    );
    expect(
      patient.therapyDemands,
      'Reduzir ansiedade e organizar rotina.',
    );
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

  test('CreatePatientRequest.toJson includes intake metadata', () {
    final json = CreatePatientRequest(
      email: 'novo@example.com',
      password: 'SenhaSegura1',
      fullName: 'Novo Paciente',
      responsiblePsychologistId: 'psych-uuid',
      birthDate: DateTime(1990, 5, 20),
      gender: 'Feminino',
      relationshipStatus: 'Casada',
      educationLevel: 'Pós-graduação',
      occupation: 'Professora',
      countryBirth: 'Brasil',
      stateBirth: 'São Paulo',
      religiousOrientation: 'Católica',
      ethnicGroup: 'Parda',
      sexualOrientation: 'Heterossexual',
      hasChildren: false,
    ).toJson();

    expect(json['birth_date'], '1990-05-20');
    expect(json['gender'], 'Feminino');
    expect(json['relationship_status'], 'Casada');
    expect(json['education_level'], 'Pós-graduação');
    expect(json['occupation'], 'Professora');
    expect(json['country_birth'], 'Brasil');
    expect(json['state_birth'], 'São Paulo');
    expect(json['religious_orientation'], 'Católica');
    expect(json['ethnic_group'], 'Parda');
    expect(json['sexual_orientation'], 'Heterossexual');
    expect(json['has_children'], isFalse);
  });
}
