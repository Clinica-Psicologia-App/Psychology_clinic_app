import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';
import 'package:terapia_esquema/features/user_management/domain/clinic_user.dart';

/// O avatar escolhido pela pessoa só aparecia para ela mesma: as listas de
/// pacientes e de usuários da clínica mostravam iniciais, porque os modelos
/// não carregavam os campos. Estes casos cobrem o caminho novo dos dados.
String _url(String path) => 'https://cdn.exemplo.com/avatars/$path';

void main() {
  group('Patient — avatar vindo do perfil vinculado', () {
    Map<String, dynamic> row({Map<String, dynamic>? accessProfile}) => {
          'id': 'pac-1',
          'full_name': 'Roberto Paciente',
          'is_active': true,
          'access_profile': accessProfile,
        };

    test('paciente sem conta fica nas iniciais', () {
      final patient = Patient.fromJson(row(), publicUrlOf: _url);

      expect(patient.avatarType, AvatarType.initials);
      expect(patient.photoUrl, isNull);
      expect(patient.avatarConfig, isNull);
    });

    test('paciente com foto expõe a URL montada', () {
      final patient = Patient.fromJson(
        row(accessProfile: {
          'is_active': true,
          'avatar_type': 'photo',
          'avatar_path': 'uid-1/profile/photo.jpg',
          'avatar_updated_at': '2026-08-02T10:00:00Z',
        }),
        publicUrlOf: _url,
      );

      expect(patient.avatarType, AvatarType.photo);
      expect(patient.photoUrl, contains('uid-1/profile/photo.jpg'));
      // Cache busting montado no mesmo lugar do próprio perfil.
      expect(patient.photoUrl, contains('?v='));
    });

    test('paciente com avatar geométrico expõe a configuração', () {
      final patient = Patient.fromJson(
        row(accessProfile: {
          'is_active': true,
          'avatar_type': 'custom',
          'avatar_config': const {'hairStyle': 'afro', 'skinTone': 'deep'},
        }),
        publicUrlOf: _url,
      );

      expect(patient.avatarType, AvatarType.custom);
      expect(patient.avatarConfig?.hairStyle, AvatarHairStyle.afro);
      expect(patient.avatarConfig?.skinTone, AvatarSkinTone.deep);
    });
  });

  group('ClinicUser — avatar na lista do administrador', () {
    Map<String, dynamic> row(Map<String, dynamic> extra) => {
          'id': 'psi-1',
          'clinic_id': 'clinic-1',
          'full_name': 'Bruno Psicólogo',
          'email': 'bruno@example.com',
          'role': 'psychologist',
          'is_active': true,
          ...extra,
        };

    test('sem avatar fica nas iniciais', () {
      final user = ClinicUser.fromJson(row(const {}), publicUrlOf: _url);

      expect(user.avatarType, AvatarType.initials);
      expect(user.photoUrl, isNull);
      expect(user.initials, 'BP');
    });

    test('com avatar geométrico expõe a configuração', () {
      final user = ClinicUser.fromJson(
        row(const {
          'avatar_type': 'custom',
          'avatar_config': {'hairStyle': 'bun'},
        }),
        publicUrlOf: _url,
      );

      expect(user.avatarType, AvatarType.custom);
      expect(user.avatarConfig?.hairStyle, AvatarHairStyle.bun);
    });

    test('iniciais usam primeiro e último nome', () {
      expect(
        ClinicUser.fromJson(row(const {'full_name': 'Ana Maria Souza'}))
            .initials,
        'AS',
      );
      expect(
        ClinicUser.fromJson(row(const {'full_name': 'Ana'})).initials,
        'A',
      );
      expect(
        ClinicUser.fromJson(row(const {'full_name': '   '})).initials,
        '?',
      );
    });
  });
}
