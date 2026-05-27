import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  test('ProfileRole parses seed roles', () {
    expect(ProfileRole.tryParse('admin'), ProfileRole.admin);
    expect(ProfileRole.tryParse('psychologist'), ProfileRole.psychologist);
    expect(ProfileRole.tryParse('patient'), ProfileRole.patient);
    expect(ProfileRole.tryParse('invalid'), isNull);
  });
}
