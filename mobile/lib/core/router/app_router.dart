import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/patient_invitations/presentation/accept_patient_invitation_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/patient_home_page.dart';
import '../../features/auth/presentation/psychologist_home_page.dart';
import '../../features/platform_admin/presentation/platform_admin_home_page.dart';
import '../../features/platform_admin/presentation/patient_overview_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/update_password_page.dart';
import '../../features/legal/presentation/legal_document_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/providers/onboarding_providers.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/daily_monitors/presentation/daily_monitor_route_helpers.dart';
import '../../features/patient_journey/presentation/patient_journey_route_helpers.dart';
import '../../features/genogram/presentation/genogram_route_helpers.dart';
import '../../features/clinical_dashboard/presentation/clinical_dashboard_route_helpers.dart';
import '../../features/clinical_reports/presentation/clinical_report_route_helpers.dart';
import '../../features/clinics/presentation/clinic_routes.dart';
import '../../features/clinics/presentation/clinics_page.dart';
import '../../features/initial_assessment/presentation/initial_assessment_route_helpers.dart';
import '../../features/mental_map/presentation/mental_map_route_helpers.dart';
import '../../features/patient_check_ins/presentation/patient_check_in_route_helpers.dart';
import '../../features/patient_timeline/presentation/patient_timeline_route_helpers.dart';
import '../../features/patient_problems/presentation/patient_problem_route_helpers.dart';
import '../../features/personality_reference/presentation/personality_reference_route_helpers.dart';
import '../../features/therapy_goals/presentation/therapy_goal_route_helpers.dart';
import '../../features/patients/presentation/create_patient_page.dart';
import '../../features/patients/domain/patient.dart';
import '../../features/patients/presentation/edit_patient_page.dart';
import '../../features/patients/presentation/patient_details_page.dart';
import '../../features/patients/presentation/patients_page.dart';
import '../../features/patient_invitations/presentation/create_patient_invitation_page.dart';
import '../../features/patient_invitations/presentation/patient_invitation_routes.dart';
import '../../features/patient_invitations/presentation/patient_invitations_page.dart';
import '../../features/profile/domain/profile_role.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/profile_routes.dart';
import '../../features/questionnaires/presentation/questionnaire_route_helpers.dart';
import '../../features/questionnaires/presentation/questionnaire_access_management_page.dart';
import '../../features/questionnaires/domain/questionnaire_session.dart';
import '../../features/questionnaires/presentation/questionnaire_answer_page.dart';
import '../../features/questionnaires/presentation/questionnaire_catalog_admin_page.dart';
import '../../features/questionnaires/presentation/questionnaire_catalog_editor_page.dart';
import '../../features/questionnaires/presentation/questionnaire_routes.dart';
import '../../features/results/presentation/result_route_helpers.dart';
import '../../features/therapy_resources/presentation/therapy_resource_route_helpers.dart';
import '../../features/user_management/presentation/user_management_page.dart';
import '../../features/user_management/presentation/user_management_routes.dart';
import 'route_access.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const updatePassword = '/update-password';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const platformHome = '/platform';
  static const psychologistHome = '/psychologist';
  static const patientHome = '/patient';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      // State is read here (not watched at provider level) so GoRouter is
      // created once and _RouterRefresh triggers re-evaluation of redirect
      // without destroying the back-stack on every auth state change.
      final authState = ref.read(authControllerProvider);
      final isPasswordRecovery = ref.read(passwordRecoveryActiveProvider);
      final onboarding = ref.read(onboardingSeenProvider);

      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;
      final isOnboarding = location == AppRoutes.onboarding;
      final isPublicRoute = RouteAccess.isPublic(location);

      // Sessão de recuperação de senha ativa: forçar /update-password.
      if (isPasswordRecovery) {
        if (location == AppRoutes.updatePassword) return null;
        return AppRoutes.updatePassword;
      }

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
        // Onboarding de primeiro acesso (apenas usuários não autenticados).
        // Deep links públicos (convite, redefinição de senha, jurídico)
        // nunca são interrompidos pelo onboarding.
        final isDeepLinkPublic = isPublicRoute && !isSplash && !isOnboarding;
        if (!isDeepLinkPublic) {
          if (onboarding.isLoading) {
            return isSplash ? null : AppRoutes.splash;
          }
          if (onboarding.valueOrNull == false) {
            return isOnboarding ? null : AppRoutes.onboarding;
          }
        }

        if (isPublicRoute) {
          return isSplash ? AppRoutes.login : null;
        }
        return AppRoutes.login;
      }

      // Usuário autenticado nunca permanece no onboarding.
      if (isOnboarding) {
        return RouteAccess.homeFor(profile.role);
      }

      if (isLogin || isSplash) {
        return RouteAccess.homeFor(profile.role);
      }

      if (isPublicRoute) {
        return null;
      }

      if (!RouteAccess.isAllowed(location, profile.role)) {
        return RouteAccess.homeFor(profile.role);
      }

      return null;
    }, // redirect
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        builder: (_, __) => const UpdatePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) =>
            const LegalDocumentPage(type: LegalDocumentType.terms),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) =>
            const LegalDocumentPage(type: LegalDocumentType.privacy),
      ),
      // Perfil do usuário — mesma rota para os três papéis.
      GoRoute(
        path: ProfileRoutes.me,
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: PatientInvitationRoutes.accept,
        builder: (_, state) => AcceptPatientInvitationPage(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.platformHome,
        builder: (_, __) => const PlatformAdminHomePage(),
        routes: [
          GoRoute(
            path: ClinicRoutes.platformList.replaceFirst('/platform/', ''),
            builder: (_, __) => const ClinicsPage(),
          ),
          GoRoute(
            path: UserManagementRoutes.platformList
                .replaceFirst('/platform/', ''),
            builder: (_, __) => const UserManagementPage(),
          ),
          GoRoute(
            path:
                QuestionnaireRoutes.adminAccess.replaceFirst('/platform/', ''),
            builder: (_, __) => const QuestionnaireAccessManagementPage(),
          ),
          GoRoute(
            path:
                QuestionnaireRoutes.adminCatalog.replaceFirst('/platform/', ''),
            builder: (_, __) => const QuestionnaireCatalogAdminPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const QuestionnaireCatalogEditorPage(),
              ),
              GoRoute(
                path: ':questionnaireId',
                builder: (_, state) => QuestionnaireCatalogEditorPage(
                  questionnaireId: state.pathParameters['questionnaireId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'preview',
                    builder: (_, state) {
                      final session = state.extra;
                      if (session is! QuestionnaireSession) {
                        return const Scaffold(
                          body: Center(
                            child: Text('Pré-visualização indisponível.'),
                          ),
                        );
                      }
                      return QuestionnaireAnswerPage(
                        session: session,
                        role: ProfileRole.platformAdmin,
                        previewMode: true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'patient-overview',
            builder: (_, __) => const PatientOverviewPage(),
          ),
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
            patientInitialAssessmentRoutes() +
            questionnaireRoutesFor(role: ProfileRole.patient) +
            patientResultsRoutes() +
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
  ref.onDispose(router.dispose);
  return router;
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
            GoRoute(
              path: 'edit',
              builder: (_, state) => EditPatientPage(
                role: role,
                patient: state.extra as Patient,
              ),
            ),
            ...questionnaireRoutesFor(
              role: role,
              patientIdPathParam: 'patientId',
            ),
            ...resultsRoutesFor(role: role),
            ...staffPatientInitialAssessmentRoutes(role: role),
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
    _ref.listen<bool>(passwordRecoveryActiveProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(onboardingSeenProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
