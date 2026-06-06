import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'personality_reference_page.dart';

List<RouteBase> staffPersonalityReferenceRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'personality-reference',
      builder: (context, state) => StaffPersonalityReferencePage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
