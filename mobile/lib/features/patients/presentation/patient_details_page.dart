import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../results/presentation/result_routes.dart';
import '../../therapy_resources/presentation/therapy_resource_routes.dart';
import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../clinical_dashboard/presentation/clinical_dashboard_routes.dart';
import '../../clinical_reports/presentation/clinical_report_routes.dart';
import '../../mental_map/presentation/mental_map_routes.dart';
import '../../patient_invitations/domain/patient_invitation_draft.dart';
import '../../patient_timeline/presentation/patient_timeline_routes.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../personality_reference/presentation/personality_reference_routes.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/future_modules_section.dart';

class PatientDetailsPage extends ConsumerWidget {
  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.role,
  });

  final String patientId;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));

    return AppScaffold(
      title: 'Paciente',
      body: asyncPatient.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Não foi possível carregar o paciente.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(patientDetailProvider(patientId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Paciente não encontrado.'));
          }
          return _PatientDetailsBody(patient: patient, role: role);
        },
      ),
    );
  }
}

class _PatientDetailsBody extends StatelessWidget {
  const _PatientDetailsBody({
    required this.patient,
    required this.role,
  });

  final Patient patient;
  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'E-mail', value: patient.email),
                _InfoRow(label: 'Telefone', value: patient.phone),
                _InfoRow(label: 'CPF', value: patient.cpf),
                _InfoRow(
                  label: 'Data de nascimento',
                  value: patient.birthDate != null
                      ? dateFormat.formatFullDate(patient.birthDate!)
                      : null,
                ),
                _InfoRow(label: 'Gênero', value: patient.gender),
                _InfoRow(
                  label: 'Estado civil',
                  value: patient.relationshipStatus,
                ),
                _InfoRow(
                  label: 'Escolaridade',
                  value: patient.educationLevel,
                ),
                _InfoRow(label: 'Ocupação', value: patient.occupation),
                _InfoRow(
                  label: 'Naturalidade',
                  value: _birthPlace(patient),
                ),
                _InfoRow(
                  label: 'Orientação religiosa',
                  value: patient.religiousOrientation,
                ),
                _InfoRow(label: 'Grupo étnico', value: patient.ethnicGroup),
                _InfoRow(
                  label: 'Orientação sexual',
                  value: patient.sexualOrientation,
                ),
                _InfoRow(
                  label: 'Filhos',
                  value: _hasChildrenLabel(patient.hasChildren),
                ),
                _InfoRow(
                  label: 'Psicólogo responsável',
                  value: patient.responsiblePsychologistName,
                ),
                _InfoRow(
                  label: 'Status',
                  value: patient.accessStatus?.label,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _IntakeContextCard(patient: patient),
        const SizedBox(height: 16),
        if (patient.accessStatus == PatientAccessStatus.noAppAccess) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: const Text('Convidar paciente'),
              subtitle: const Text(
                'Gerar link para o paciente criar senha e concluir o primeiro acesso.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                PatientRoutes.invitationCreate(role),
                extra: PatientInvitationDraft(
                  fullName: patient.fullName,
                  email: patient.email,
                  phone: patient.phone,
                  responsiblePsychologistId: patient.responsiblePsychologistId,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Gerar relatório'),
            subtitle: const Text(
              'PDF clínico supervisionado (somente equipe).',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              ClinicalReportRoutes.staffOptions(
                role: role,
                patientId: patient.id,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FutureModulesSection(
          onQuestionnairesTap: () => context.push(
            QuestionnaireRoutes.list(
              role: role,
              patientId: patient.id,
            ),
          ),
          onResultsTap: () => context.push(
            ResultRoutes.list(
              role: role,
              patientId: patient.id,
            ),
          ),
          onTherapyResourcesTap: () => context.push(
            TherapyResourceRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onDailyMonitorsTap: () => context.push(
            DailyMonitorRoutes.staffHistory(
              role: role,
              patientId: patient.id,
            ),
          ),
          onTherapyGoalsTap: () => context.push(
            TherapyGoalRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onProblemsTap: () => context.push(
            PatientProblemRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onCheckInsTap: () => context.push(
            PatientCheckInRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onTimelineTap: () => context.push(
            PatientTimelineRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onGenogramTap: () => context.push(
            GenogramRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onMentalMapTap: () => context.push(
            MentalMapRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onClinicalDashboardTap: () => context.push(
            ClinicalDashboardRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
          onPersonalityReferenceTap: () => context.push(
            PersonalityReferenceRoutes.staffList(
              role: role,
              patientId: patient.id,
            ),
          ),
        ),
      ],
    );
  }

  String? _birthPlace(Patient patient) {
    final parts = [
      patient.stateBirth,
      patient.countryBirth,
    ].where((value) => value != null && value.trim().isNotEmpty).cast<String>();

    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  String? _hasChildrenLabel(bool? hasChildren) {
    if (hasChildren == null) return null;
    return hasChildren ? 'Sim' : 'Não';
  }
}

class _IntakeContextCard extends ConsumerStatefulWidget {
  const _IntakeContextCard({required this.patient});

  final Patient patient;

  @override
  ConsumerState<_IntakeContextCard> createState() => _IntakeContextCardState();
}

class _IntakeContextCardState extends ConsumerState<_IntakeContextCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intakeAvailable = widget.patient.supportsIntakeContext;
    final sections = [
      (
        title: 'Síntese inicial',
        body: widget.patient.intakeSummary,
      ),
      (
        title: 'Contexto de vida atual',
        body: widget.patient.currentLifeContext,
      ),
      (
        title: 'Demandas terapêuticas',
        body: widget.patient.therapyDemands,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Anamnese e contexto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (intakeAvailable)
                  TextButton.icon(
                    onPressed: _saving ? null : _openEditDialog,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              intakeAvailable
                  ? 'Bloco clínico inicial para registrar a leitura do caso antes da formulação detalhada.'
                  : 'Anamnese disponível após atualização do banco.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (intakeAvailable)
              for (final section in sections) ...[
                _InfoBlock(
                  title: section.title,
                  body: section.body,
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog() async {
    if (!widget.patient.supportsIntakeContext) {
      return;
    }

    final intakeController =
        TextEditingController(text: widget.patient.intakeSummary ?? '');
    final contextController =
        TextEditingController(text: widget.patient.currentLifeContext ?? '');
    final demandsController =
        TextEditingController(text: widget.patient.therapyDemands ?? '');

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Editar anamnese e contexto'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MultilineField(
                      controller: intakeController,
                      label: 'Síntese inicial',
                      hint:
                          'Resumo livre da anamnese, história inicial e pontos relevantes.',
                    ),
                    const SizedBox(height: 16),
                    _MultilineField(
                      controller: contextController,
                      label: 'Contexto de vida atual',
                      hint:
                          'Momento atual, rotina, relações, trabalho, estressores e suporte.',
                    ),
                    const SizedBox(height: 16),
                    _MultilineField(
                      controller: demandsController,
                      label: 'Demandas terapêuticas',
                      hint:
                          'Queixas principais, objetivos trazidos e foco combinado em terapia.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() => _saving = true);
      await ref.read(patientsRepositoryProvider).updatePatientIntake(
            patientId: widget.patient.id,
            intakeSummary: intakeController.text,
            currentLifeContext: contextController.text,
            therapyDemands: demandsController.text,
          );
      ref.invalidate(patientDetailProvider(widget.patient.id));
      ref.invalidate(patientsListProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      if (message.contains('20250604193022_patient_intake_context.sql') ||
          message.contains('campos de anamnese')) {
        showErrorBanner(
          context,
          'Anamnese disponível após atualização do banco.',
        );
      } else {
        showErrorBanner(context, e);
      }
    } finally {
      intakeController.dispose();
      contextController.dispose();
      demandsController.dispose();
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body != null && body!.trim().isNotEmpty
              ? body!.trim()
              : 'Ainda não preenchido.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: body != null && body!.trim().isNotEmpty
                ? null
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MultilineField extends StatelessWidget {
  const _MultilineField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      minLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
