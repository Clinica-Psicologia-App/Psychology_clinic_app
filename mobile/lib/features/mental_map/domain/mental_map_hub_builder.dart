import '../../profile/domain/profile_role.dart';
import '../presentation/mental_map_navigation_targets.dart';
import 'mental_case_map.dart';
import 'mental_map_node_detail.dart';

MentalMapNodeDetail buildMentalMapNodeDetail({
  required MentalCaseMapNode node,
  required ProfileRole role,
  String? patientId,
}) {
  final routes = _routesForNode(
    nodeId: node.id,
    role: role,
    patientId: patientId,
    responseId: node.responseId,
  );

  return MentalMapNodeDetail(
    id: node.id,
    title: node.title,
    items: node.items,
    dataSource: node.dataSource,
    lastUpdatedAt: node.lastUpdatedAt,
    responseId: node.responseId,
    ctaLabel: routes.primaryLabel,
    secondaryCtaLabel: routes.secondaryLabel,
    secondaryRoute: routes.secondaryRoute,
    severityColorKey: node.aggregateSeverityColorKey,
  );
}

String? resolvePrimaryRoute({
  required MentalMapNodeDetail detail,
  required ProfileRole role,
  String? patientId,
}) {
  return _routesForNode(
    nodeId: detail.id,
    role: role,
    patientId: patientId,
    responseId: detail.responseId,
  ).primaryRoute;
}

String? resolveSecondaryRoute({
  required MentalMapNodeDetail detail,
  required ProfileRole role,
  String? patientId,
}) {
  return _routesForNode(
    nodeId: detail.id,
    role: role,
    patientId: patientId,
    responseId: detail.responseId,
  ).secondaryRoute;
}

class _NodeRoutes {
  const _NodeRoutes({
    required this.primaryLabel,
    this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  final String primaryLabel;
  final String? primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;
}

_NodeRoutes _routesForNode({
  required String nodeId,
  required ProfileRole role,
  String? patientId,
  String? responseId,
}) {
  switch (nodeId) {
    case 'schemas':
    case 'modes':
    case 'attachment':
    case 'coping':
    case 'parental':
      return _NodeRoutes(
        primaryLabel: 'Abrir dashboard clínico',
        primaryRoute: MentalMapNavigationTargets.clinicalDashboard(
          role: role,
          patientId: patientId,
        ),
        secondaryLabel: _resultLabel(role, responseId),
        secondaryRoute: MentalMapNavigationTargets.questionnaireResult(
          role: role,
          patientId: patientId,
          responseId: responseId,
        ),
      );
    case 'problems':
      return _NodeRoutes(
        primaryLabel: 'Abrir problemas',
        primaryRoute: MentalMapNavigationTargets.problems(
          role: role,
          patientId: patientId,
        ),
      );
    case 'goals':
      return _NodeRoutes(
        primaryLabel: 'Abrir objetivos',
        primaryRoute: MentalMapNavigationTargets.therapyGoals(
          role: role,
          patientId: patientId,
        ),
      );
    case 'history':
      return _NodeRoutes(
        primaryLabel: 'Abrir linha do tempo',
        primaryRoute: MentalMapNavigationTargets.timeline(
          role: role,
          patientId: patientId,
        ),
        secondaryLabel: 'Abrir genograma',
        secondaryRoute: MentalMapNavigationTargets.genogram(
          role: role,
          patientId: patientId,
        ),
      );
    default:
      return const _NodeRoutes(
        primaryLabel: 'Ver detalhes',
      );
  }
}

String? _resultLabel(ProfileRole role, String? responseId) {
  if (role == ProfileRole.patient || responseId == null) return null;
  return 'Ver resultado';
}
