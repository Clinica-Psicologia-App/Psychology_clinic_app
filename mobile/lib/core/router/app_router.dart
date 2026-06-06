import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/admin_home_page.dart';
import '../../features/patient_invitations/presentation/accept_patient_invitation_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/patient_home_page.dart';
import '../../features/auth/presentation/psychologist_home_page.dart';
import '../../features/professional_onboarding/presentation/professional_sign_up_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/daily_monitors/presentation/daily_monitor_route_helpers.dart';
import '../../features/patient_journey/presentation/patient_journey_route_helpers.dart';
import '../../features/genogram/presentation/genogram_route_helpers.dart';
import '../../features/clinical_dashboard/presentation/clinical_dashboard_route_helpers.dart';
import '../../features/clinical_reports/presentation/clinical_report_route_helpers.dart';
import '../../features/mental_map/presentation/mental_map_route_helpers.dart';
import '../../features/patient_check_ins/presentation/patient_check_in_route_helpers.dart';
import '../../features/patient_timeline/presentation/patient_timeline_route_helpers.dart';
import '../../features/patient_problems/presentation/patient_problem_route_helpers.dart';
import '../../features/personality_reference/presentation/personality_reference_route_helpers.dart';
import '../../features/therapy_goals/presentation/therapy_goal_route_helpers.dart';
import '../../features/patients/presentation/create_patient_page.dart';
import '../../features/patients/presentation/patient_details_page.dart';
import '../../features/patients/presentation/patients_page.dart';
import '../../features/patient_invitations/presentation/create_patient_invitation_page.dart';
import '../../features/patient_invitations/presentation/patient_invitation_routes.dart';
import '../../features/patient_invitations/presentation/patient_invitations_page.dart';
import '../../features/profile/domain/profile_role.dart';
import '../../features/questionnaires/presentation/questionnaire_route_helpers.dart';
import '../../features/questionnaires/presentation/questionnaire_access_management_page.dart';
import '../../features/questionnaires/presentation/questionnaire_routes.dart';
import '../../features/results/presentation/result_route_helpers.dart';
import '../../features/therapy_resources/presentation/therapy_resource_route_helpers.dart';
import 'route_access.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const professionalSignUp = '/professional-sign-up';
  static const adminHome = '/admin';
  static const psychologistHome = '/psychologist';
  static const patientHome = '/patient';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;
      final isPublicRoute = RouteAccess.isPublic(location);

      if (authState.isLoading) {
        if (isSplash || isLogin || isPublicRoute) return null;
        return AppRoutes.splash;
      }

      if (authState.hasError) {
        if (!isLogin && !isSplash && !isPublicRoute) return AppRoutes.login;
        return null;
      }

      final profile = authState.valueOrNull;

      if (profile == null) {
        if (isPublicRoute) {
          return isSplash ? AppRoutes.login : null;
        }
        return AppRoutes.login;
      }

      if (isPublicRoute) {
        return null;
      }

      if (isLogin || isSplash) {
        return RouteAccess.homeFor(profile.role);
      }

      if (!RouteAccess.isAllowed(location, profile.role)) {
        return RouteAccess.homeFor(profile.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.professionalSignUp,
        builder: (_, __) => const ProfessionalSignUpPage(),
      ),
      GoRoute(
        path: PatientInvitationRoutes.accept,
        builder: (_, state) => AcceptPatientInvitationPage(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (_, __) => const AdminHomePage(),
        routes: [
          ...patientInvitationRoutesFor(ProfileRole.admin),
          GoRoute(
            path: QuestionnaireRoutes.adminAccess.replaceFirst('/admin/', ''),
            builder: (_, __) => const QuestionnaireAccessManagementPage(),
          ),
          ..._staffPatientRoutes(ProfileRole.admin),
        ],
      ),
      GoRoute(
        path: AppRoutes.psychologistHome,
        builder: (_, __) => const PsychologistHomePage(),
        routes: [
          ...patientInvitationRoutesFor(ProfileRole.psychologist),
          ..._staffPatientRoutes(ProfileRole.psychologist),
        ],
      ),
      GoRoute(
        path: AppRoutes.patientHome,
        builder: (_, __) => const PatientHomePage(),
        routes: patientJourneyRoutes() +
            questionnaireRoutesFor(role: ProfileRole.patient) +
            patientTherapyGoalRoutes() +
            patientProblemRoutes() +
            patientCheckInRoutes() +
            patientTimelineRoutes() +
            patientGenogramRoutes() +
            patientMentalMapRoutes() +
            patientClinicalDashboardRoutes() +
            patientTherapyResourceRoutes() +
            patientDailyMonitorRoutes(),
      ),
    ],
  );
});

List<RouteBase> patientInvitationRoutesFor(ProfileRole role) {
  return [
    GoRoute(
      path: 'patient-invitations',
      builder: (_, __) => PatientInvitationsPage(role: role),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, state) => CreatePatientInvitationPage(
            role: role,
            draft: state.extra as dynamic,
          ),
        ),
      ],
    ),
  ];
}

List<RouteBase> _staffPatientRoutes(ProfileRole role) {
  return [
    GoRoute(
      path: 'patients',
      builder: (_, __) => PatientsPage(role: role),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => CreatePatientPage(role: role),
        ),
        GoRoute(
          path: ':patientId',
          builder: (_, state) => PatientDetailsPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
          routes: [
            ...questionnaireRoutesFor(
              role: role,
              patientIdPathParam: 'patientId',
            ),
            ...resultsRoutesFor(role: role),
            ...staffTherapyResourceRoutes(role: role),
            ...staffDailyMonitorRoutes(role: role),
            ...staffTherapyGoalRoutes(role: role),
            ...staffPatientProblemRoutes(role: role),
            ...staffPatientCheckInRoutes(role: role),
            ...staffPatientTimelineRoutes(role: role),
            ...staffPatientGenogramRoutes(role: role),
            ...staffPatientMentalMapRoutes(role: role),
            ...staffClinicalDashboardRoutes(role: role),
            ...staffPersonalityReferenceRoutes(role: role),
            ...staffClinicalReportRoutes(role: role),
          ],
        ),
      ],
    ),
  ];
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<String?>(authRedirectMessageProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
