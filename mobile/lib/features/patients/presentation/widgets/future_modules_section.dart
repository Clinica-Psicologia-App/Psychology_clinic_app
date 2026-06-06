import 'package:flutter/material.dart';

/// Módulos do paciente (staff).
class FutureModulesSection extends StatelessWidget {
  const FutureModulesSection({
    super.key,
    this.onQuestionnairesTap,
    this.onResultsTap,
    this.onTherapyResourcesTap,
    this.onDailyMonitorsTap,
    this.onTherapyGoalsTap,
    this.onProblemsTap,
    this.onCheckInsTap,
    this.onTimelineTap,
    this.onGenogramTap,
    this.onMentalMapTap,
    this.onClinicalDashboardTap,
    this.onPersonalityReferenceTap,
  });

  final VoidCallback? onQuestionnairesTap;
  final VoidCallback? onResultsTap;
  final VoidCallback? onTherapyResourcesTap;
  final VoidCallback? onDailyMonitorsTap;
  final VoidCallback? onTherapyGoalsTap;
  final VoidCallback? onProblemsTap;
  final VoidCallback? onCheckInsTap;
  final VoidCallback? onTimelineTap;
  final VoidCallback? onGenogramTap;
  final VoidCallback? onMentalMapTap;
  final VoidCallback? onClinicalDashboardTap;
  final VoidCallback? onPersonalityReferenceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Questionários'),
            subtitle: const Text(
              'Ver disponíveis e iniciar aplicação para este paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onQuestionnairesTap,
            enabled: onQuestionnairesTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Resultados (lista)'),
            subtitle: const Text(
              'Respostas concluídas e detalhe por categoria.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onResultsTap,
            enabled: onResultsTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Dashboard clínico'),
            subtitle: const Text(
              'Gráficos YSQ/YAMI a partir do snapshot (somente leitura).',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onClinicalDashboardTap,
            enabled: onClinicalDashboardTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.psychology_alt_outlined),
            title: const Text('Referência de personalidade'),
            subtitle: const Text(
              'Fatores, facetas e sugestões clínicas de leitura.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPersonalityReferenceTap,
            enabled: onPersonalityReferenceTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Recursos terapêuticos'),
            subtitle: const Text(
              'Liberar materiais e acompanhar progresso do paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTherapyResourcesTap,
            enabled: onTherapyResourcesTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: const Text('Problemas'),
            subtitle: const Text(
              'Queixas e focos de trabalho do paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onProblemsTap,
            enabled: onProblemsTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Objetivos da terapia'),
            subtitle: const Text(
              'Metas terapêuticas do paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTherapyGoalsTap,
            enabled: onTherapyGoalsTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Check-ins'),
            subtitle: const Text(
              'Registros rápidos do paciente (somente leitura).',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onCheckInsTap,
            enabled: onCheckInsTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: const Text('Mapa mental'),
            subtitle: const Text(
              'Visão integrada dos dados clínicos do paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onMentalMapTap,
            enabled: onMentalMapTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: const Text('Genograma'),
            subtitle: const Text(
              'Pessoas e relações familiares do paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onGenogramTap,
            enabled: onGenogramTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.timeline_outlined),
            title: const Text('Linha do tempo'),
            subtitle: const Text(
              'Eventos importantes da história e do processo terapêutico.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTimelineTap,
            enabled: onTimelineTap != null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.monitor_heart_outlined),
            title: const Text('Monitor diário'),
            subtitle: const Text(
              'Histórico de acompanhamentos registrados pelo paciente.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onDailyMonitorsTap,
            enabled: onDailyMonitorsTap != null,
          ),
        ),
      ],
    );
  }
}
