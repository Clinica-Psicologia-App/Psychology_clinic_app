import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  test('ProfileRole labels are defined', () {
    expect(ProfileRole.admin.label, 'Administrador');
    expect(ProfileRole.patient.label, 'Paciente');
  });
}
