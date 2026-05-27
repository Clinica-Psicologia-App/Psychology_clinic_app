import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../features/auth/presentation/admin_home_page.dart';

import '../../features/auth/presentation/login_page.dart';

import '../../features/auth/presentation/patient_home_page.dart';

import '../../features/auth/presentation/psychologist_home_page.dart';

import '../../features/auth/presentation/splash_page.dart';

import '../../features/auth/providers/auth_providers.dart';

import '../../features/patients/presentation/create_patient_page.dart';

import '../../features/patients/presentation/patient_details_page.dart';

import '../../features/patients/presentation/patient_routes.dart';

import '../../features/patients/presentation/patients_page.dart';

import '../../features/profile/domain/profile_role.dart';



abstract final class AppRoutes {

  static const splash = '/';

  static const login = '/login';

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



      if (authState.isLoading && isSplash) {

        return null;

      }



      if (authState.isLoading) {

        return AppRoutes.splash;

      }



      if (authState.hasError) {

        if (!isLogin) return AppRoutes.login;

        return null;

      }



      final profile = authState.valueOrNull;



      if (profile == null) {

        if (isLogin || isSplash) {

          return isSplash ? AppRoutes.login : null;

        }

        return AppRoutes.login;

      }



      if (profile.role == ProfileRole.patient &&

          PatientRoutes.isStaffPatientsPath(location)) {

        return AppRoutes.patientHome;

      }



      if (isLogin || isSplash) {

        return _homeForRole(profile.role);

      }



      if (!PatientRoutes.pathMatchesRole(location, profile.role)) {

        return _homeForRole(profile.role);

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

        path: AppRoutes.adminHome,

        builder: (_, __) => const AdminHomePage(),

        routes: _staffPatientRoutes(ProfileRole.admin),

      ),

      GoRoute(

        path: AppRoutes.psychologistHome,

        builder: (_, __) => const PsychologistHomePage(),

        routes: _staffPatientRoutes(ProfileRole.psychologist),

      ),

      GoRoute(

        path: AppRoutes.patientHome,

        builder: (_, __) => const PatientHomePage(),

      ),

    ],

  );

});



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

        ),

      ],

    ),

  ];

}



String _homeForRole(ProfileRole role) {

  switch (role) {

    case ProfileRole.admin:

      return AppRoutes.adminHome;

    case ProfileRole.psychologist:

      return AppRoutes.psychologistHome;

    case ProfileRole.patient:

      return AppRoutes.patientHome;

  }

}



class _RouterRefresh extends ChangeNotifier {

  _RouterRefresh(this._ref) {

    _ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, __) {

      notifyListeners();

    });

  }



  final Ref _ref;

}


