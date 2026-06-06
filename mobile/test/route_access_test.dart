import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/router/route_access.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
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
      RouteAccess.isAllowed('/patient/journey/upcoming/genogram', ProfileRole.patient),
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
        ProfileRole.admin,
      ),
      isTrue,
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
        ProfileRole.admin,
      ),
      isTrue,
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
        ProfileRole.admin,
      ),
      isTrue,
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
        ProfileRole.admin,
      ),
      isTrue,
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
      RouteAccess.isAllowed('/patient/journey', ProfileRole.admin),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/therapy-goals', ProfileRole.psychologist),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/patient/clinical-dashboard', ProfileRole.admin),
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

  test('professional sign up route is public and does not affect login flow', () {
    expect(RouteAccess.isPublic('/professional-sign-up'), isTrue);
    expect(
      RouteAccess.isAllowed('/professional-sign-up', ProfileRole.admin),
      isTrue,
    );
  });

  test('admin cannot access psychologist routes', () {
    expect(
      RouteAccess.isAllowed('/psychologist/patients', ProfileRole.admin),
      isFalse,
    );
    expect(
      RouteAccess.isAllowed('/admin/patients', ProfileRole.admin),
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
    expect(RouteAccess.homeFor(ProfileRole.admin), '/admin');
    expect(RouteAccess.homeFor(ProfileRole.patient), '/patient');
  });
}
