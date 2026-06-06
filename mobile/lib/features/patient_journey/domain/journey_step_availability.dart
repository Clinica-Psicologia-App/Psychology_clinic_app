/// Estado de exibição de um passo na trilha do paciente.
enum JourneyStepAvailability {
  available,
  inProgress,
  inDevelopment,
  completed,
  blocked,
}

extension JourneyStepAvailabilityLabels on JourneyStepAvailability {
  String get label => switch (this) {
        JourneyStepAvailability.available => 'Disponível',
        JourneyStepAvailability.inProgress => 'Em andamento',
        JourneyStepAvailability.inDevelopment => 'Em desenvolvimento',
        JourneyStepAvailability.completed => 'Concluído',
        JourneyStepAvailability.blocked => 'Bloqueado',
      };

  bool get isNavigableToModule => switch (this) {
        JourneyStepAvailability.available ||
        JourneyStepAvailability.inProgress ||
        JourneyStepAvailability.completed =>
          true,
        JourneyStepAvailability.inDevelopment ||
        JourneyStepAvailability.blocked =>
          false,
      };

  bool get opensPlaceholder => switch (this) {
        JourneyStepAvailability.inDevelopment ||
        JourneyStepAvailability.blocked =>
          true,
        JourneyStepAvailability.available ||
        JourneyStepAvailability.inProgress ||
        JourneyStepAvailability.completed =>
          false,
      };
}
