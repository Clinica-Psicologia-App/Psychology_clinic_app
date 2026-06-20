import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  test('ProfileRole parses seed roles', () {
    expect(ProfileRole.tryParse('platform_admin'), ProfileRole.platformAdmin);
    expect(ProfileRole.tryParse('admin'), ProfileRole.platformAdmin);
    expect(ProfileRole.tryParse('psychologist'), ProfileRole.psychologist);
    expect(ProfileRole.tryParse('patient'), ProfileRole.patient);
    expect(ProfileRole.tryParse('invalid'), isNull);
  });

  test('ProfileRole maps storage values', () {
    expect(ProfileRole.platformAdmin.storageValue, 'platform_admin');
    expect(ProfileRole.psychologist.storageValue, 'psychologist');
    expect(ProfileRole.patient.storageValue, 'patient');
  });
}
