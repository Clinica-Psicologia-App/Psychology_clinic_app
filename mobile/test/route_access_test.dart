import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_routes.dart';
import 'package:terapia_esquema/core/router/route_access.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  _adminPatientAccess();

  test('patient cannot access staff routes', () {
    expect(
      RouteAccess.isAllowed('/admin/patients', ProfileRole.patient),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/psychologist/patients/abc', ProfileRole.patient),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/daily-monitors', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed('/patient/journey', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
          '/patient/journey/upcoming/genogram', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed('/patient/therapy-goals', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/therapy-goals',
        ProfileRole.psychologist,
      ),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed('/patient/problems', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/problems',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/check-ins', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/check-ins',
        ProfileRole.psychologist,
      ),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed('/patient/timeline', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/timeline',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/genogram', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/genogram',
        ProfileRole.psychologist,
      ),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed('/patient/mental-map', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/mental-map',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/clinical-dashboard', ProfileRole.patient),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/clinical-dashboard',
        ProfileRole.psychologist,
      ),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/clinical-report',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/clinical-report',
        ProfileRole.patient,
      ),
      isFalse,
    );
  });

  test('staff cannot access patient-only routes', () {
    expect(
      RouteAccess.isAllowed('/patient/journey', ProfileRole.platformAdmin),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/therapy-goals', ProfileRole.psychologist),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed(
        '/patient/clinical-dashboard',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/mental-map', ProfileRole.psychologist),
      isFalse,
    );
  });

  test('patient cannot access staff results routes', () {
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/results',
        ProfileRole.patient,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients/abc/results/resp-1',
        ProfileRole.patient,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed(
        '/admin/patients/abc/clinical-dashboard',
        ProfileRole.patient,
      ),
      isFalse,
    );
  });

  test('journey placeholder route allowed for patient', () {
    expect(
      RouteAccess.isAllowed(
        '/patient/journey/upcoming/anamnesis',
        ProfileRole.patient,
      ),
      isTrue,
    );
  });

  test('accept invitation route is public', () {
    expect(RouteAccess.isPublic('/accept-invitation'), isTrue);
    expect(
      RouteAccess.isAllowed('/accept-invitation', ProfileRole.patient),
      isTrue,
    );
  });

  test('professional sign up route is not publicly accessible', () {
    expect(RouteAccess.isPublic('/professional-sign-up'), isFalse);
    expect(
      RouteAccess.isAllowed(
        '/professional-sign-up',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
  });

  test('platform admin cannot access clinical routes', () {
    expect(
      RouteAccess.isAllowed(
        '/psychologist/patients',
        ProfileRole.platformAdmin,
      ),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/platform/users', ProfileRole.platformAdmin),
      isTrue,
    );
  });

  test('psychologist cannot access admin routes', () {
    expect(
      RouteAccess.isAllowed('/admin', ProfileRole.psychologist),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/psychologist', ProfileRole.psychologist),
      isTrue,
    );
  });

  test('homeFor returns role prefix', () {
    expect(RouteAccess.homeFor(ProfileRole.platformAdmin), '/platform');
    expect(RouteAccess.homeFor(ProfileRole.patient), '/patient');
  });
}

/// O admin já teve uma rota de lista de pacientes que a RLS garantia estar
/// sempre vazia: a migration 20260720120011 tirou o acesso dele a linhas
/// individuais, por privacidade clínica, mas a interface continuou oferecendo
/// a tela — e ela dizia "nenhum paciente encontrado", que é falso do ponto de
/// vista da clínica. Estes casos travam a decisão.
void _adminPatientAccess() {
  group('acesso do admin a pacientes', () {
    test('não existe rota de lista de pacientes para o admin', () {
      expect(
        () => PatientRoutes.list(ProfileRole.platformAdmin),
        throwsStateError,
      );
    });

    test('psicólogo continua com a lista', () {
      expect(
        PatientRoutes.list(ProfileRole.psychologist),
        '/psychologist/patients',
      );
    });
  });
}
