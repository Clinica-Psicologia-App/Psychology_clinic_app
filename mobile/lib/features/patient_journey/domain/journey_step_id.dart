/// Identificadores estáveis dos passos da trilha (rotas e placeholders).
enum JourneyStepId {
  questionnaires,
  dailyMonitor,
  library,
  results,
  therapyGoals,
  problems,
  checkIn,
  genogram,
  timeline,
  mentalMap,
}

extension JourneyStepIdRoute on JourneyStepId {
  String get routeKey => name;
}

JourneyStepId? journeyStepIdFromRouteKey(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final id in JourneyStepId.values) {
    if (id.name == value) return id;
  }
  return null;
}
