import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/therapy_goal.dart';
import '../domain/therapy_goal_input.dart';
import '../domain/therapy_goal_status.dart';
import '../providers/therapy_goals_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class TherapyGoalFormPage extends ConsumerStatefulWidget {
  const TherapyGoalFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.goalId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? goalId;

  bool get isEdit => goalId != null;
  bool get isStaff => role != ProfileRole.patient;

  @override
  ConsumerState<TherapyGoalFormPage> createState() =>
      _TherapyGoalFormPageState();
}

class _TherapyGoalFormPageState extends ConsumerState<TherapyGoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _targetDate;
  TherapyGoalStatus _status = TherapyGoalStatus.active;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateFromGoal(TherapyGoal goal) {
    if (_loaded) return;
    _loaded = true;
    final input = TherapyGoalInput.fromGoal(goal);
    _titleController.text = input.title;
    _descriptionController.text = input.description ?? '';
    _targetDate = input.targetDate;
    _status = goal.status;
  }

  TherapyGoalInput _buildInput() {
    return TherapyGoalInput(
      title: _titleController.text,
      description: _descriptionController.text,
      targetDate: widget.isStaff ? _targetDate : null,
      status:
          widget.isStaff || widget.isEdit ? _status : TherapyGoalStatus.active,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _buildInput();
    final localError = input.validate();
    if (localError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localError)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(therapyGoalsRepositoryProvider);

      if (widget.isEdit) {
        if (widget.isStaff) {
          await repo.updateAsStaff(id: widget.goalId!, input: input);
        } else {
          await repo.updateAsPatient(id: widget.goalId!, input: input);
        }
      } else {
        final ctx = await repo.resolvePatientContext(
          patientId: widget.patientId,
        );
        await repo.create(
          clinicId: ctx.clinicId,
          patientId: ctx.patientId,
          input: input,
        );
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? userMessageFor(e)
                  : 'Não foi possível salvar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final goalAsync = ref.watch(therapyGoalDetailProvider(widget.goalId!));
      return goalAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          accent: AppColors.turquoise,
          body: BrandLoader(),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          accent: AppColors.turquoise,
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  ref.invalidate(therapyGoalDetailProvider(widget.goalId!)),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (goal) {
          if (goal == null) {
            return const AppScaffold(
              title: 'Objetivo',
              accent: AppColors.turquoise,
              body: Center(child: Text('Objetivo não encontrado.')),
            );
          }
          _populateFromGoal(goal);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar objetivo' : 'Novo objetivo',
      accent: AppColors.turquoise,
      body: Form(
        key: _formKey,
        child: MotionReveal(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              AppPageHeader(
                icon: Icons.flag_outlined,
                title: widget.isEdit ? 'Editar objetivo' : 'Novo objetivo',
                subtitle:
                    'Registre metas terapêuticas de forma clara para acompanhar direção, avanço e conclusão do trabalho clínico.',
                metadata: [
                  StatusChip(
                    label: widget.isStaff ? 'Visível à equipe' : 'Sua jornada',
                    tone: AppStatusTone.info,
                    icon: widget.isStaff
                        ? Icons.groups_outlined
                        : Icons.person_outline,
                  ),
                  if (widget.isEdit)
                    StatusChip(
                      label: _status.label,
                      tone: _goalStatusTone(_status),
                      icon: Icons.flag_outlined,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Dados principais',
                subtitle:
                    'Use um título objetivo e complemente com uma descrição quando necessário.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex.: Reduzir episódios de ansiedade',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (widget.isStaff) ...[
                const SizedBox(height: AppSpacing.lg),
                const AppSectionHeader(
                  title: 'Acompanhamento',
                  subtitle:
                      'Defina prazo e status quando o objetivo estiver sendo conduzido pela equipe.',
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data alvo (opcional)'),
                  subtitle: Text(
                    _targetDate == null
                        ? 'Não definida'
                        : MaterialLocalizations.of(context).formatFullDate(
                            _targetDate!,
                          ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickTargetDate,
                  ),
                ),
                if (_targetDate != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _targetDate = null),
                      child: const Text('Remover data alvo'),
                    ),
                  ),
              ],
              if (widget.isStaff && widget.isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<TherapyGoalStatus>(
                  segments: const [
                    ButtonSegment(
                      value: TherapyGoalStatus.active,
                      label: Text('Ativo'),
                    ),
                    ButtonSegment(
                      value: TherapyGoalStatus.completed,
                      label: Text('Concluído'),
                    ),
                    ButtonSegment(
                      value: TherapyGoalStatus.archived,
                      label: Text('Arquivado'),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (set) {
                    setState(() => _status = set.first);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isEdit ? 'Salvar alterações' : 'Criar objetivo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AppStatusTone _goalStatusTone(TherapyGoalStatus status) {
  return switch (status) {
    TherapyGoalStatus.active => AppStatusTone.inProgress,
    TherapyGoalStatus.completed => AppStatusTone.completed,
    TherapyGoalStatus.archived => AppStatusTone.neutral,
  };
}
