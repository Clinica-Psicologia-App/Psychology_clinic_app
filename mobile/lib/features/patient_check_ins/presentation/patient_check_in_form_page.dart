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
import '../domain/patient_check_in.dart';
import '../domain/patient_check_in_input.dart';
import '../providers/patient_check_ins_providers.dart';
import 'widgets/patient_check_in_widgets.dart';

class PatientCheckInFormPage extends ConsumerStatefulWidget {
  const PatientCheckInFormPage({super.key, this.checkInId});

  final String? checkInId;

  bool get isEdit => checkInId != null;

  @override
  ConsumerState<PatientCheckInFormPage> createState() =>
      _PatientCheckInFormPageState();
}

class _PatientCheckInFormPageState
    extends ConsumerState<PatientCheckInFormPage> {
  final _notesController = TextEditingController();

  int _mood = 5;
  int _anxiety = 5;
  int _energy = 5;
  int _problemIntensity = 5;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromCheckIn(PatientCheckIn checkIn) {
    if (_loaded) return;
    _loaded = true;
    _mood = checkIn.moodScore ?? 5;
    _anxiety = checkIn.anxietyScore ?? 5;
    _energy = checkIn.energyScore ?? 5;
    _problemIntensity = checkIn.problemIntensityScore ?? 5;
    _notesController.text = checkIn.notes ?? '';
  }

  PatientCheckInInput _buildInput() {
    return PatientCheckInInput(
      moodScore: _mood,
      anxietyScore: _anxiety,
      energyScore: _energy,
      problemIntensityScore: _problemIntensity,
      notes: _notesController.text,
    );
  }

  Future<void> _save() async {
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
      final repo = ref.read(patientCheckInsRepositoryProvider);

      if (widget.isEdit) {
        final existing = await repo.getById(widget.checkInId!);
        if (existing == null) {
          throw AppException(
            code: AppExceptionCodes.notFound,
            message: 'Check-in não encontrado.',
          );
        }
        await repo.update(
          id: widget.checkInId!,
          input: input,
          existing: existing,
        );
      } else {
        final today = await repo.findTodayForCurrentPatient();
        if (today != null) {
          await repo.update(id: today.id, input: input, existing: today);
        } else {
          final ctx = await repo.resolvePatientContext();
          await repo.create(
            clinicId: ctx.clinicId,
            patientId: ctx.patientId,
            input: input,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in registrado. Obrigado por se cuidar hoje.'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final checkInAsync =
          ref.watch(patientCheckInDetailProvider(widget.checkInId!));
      return checkInAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          accent: AppColors.turquoise,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          accent: AppColors.turquoise,
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                patientCheckInDetailProvider(widget.checkInId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (checkIn) {
          if (checkIn == null) {
            return const AppScaffold(
              title: 'Check-in',
              accent: AppColors.turquoise,
              body: Center(child: Text('Check-in não encontrado.')),
            );
          }
          if (!checkIn.isEditableToday) {
            return const AppScaffold(
              title: 'Check-in',
              accent: AppColors.turquoise,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Este check-in não pode mais ser editado (apenas o de hoje).',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          _populateFromCheckIn(checkIn);
          return _buildForm(context, isEditToday: true);
        },
      );
    }

    return _buildForm(context, isEditToday: false);
  }

  Widget _buildForm(BuildContext context, {required bool isEditToday}) {
    return AppScaffold(
      title: widget.isEdit || isEditToday ? 'Editar check-in' : 'Novo check-in',
      accent: AppColors.turquoise,
      body: MotionReveal(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            AppPageHeader(
              icon: Icons.monitor_heart_outlined,
              title:
                  widget.isEdit || isEditToday ? 'Editar check-in' : 'Check-in',
              subtitle:
                  'Registre como você está hoje. As escalas vão de 0 a 10 e ajudam a acompanhar mudanças ao longo do tempo.',
              metadata: [
                StatusChip(
                  label: isEditToday ? 'Editando hoje' : 'Registro de hoje',
                  tone: AppStatusTone.info,
                  icon: Icons.today_outlined,
                ),
                StatusChip(
                  label: 'Humor $_mood',
                  tone: AppStatusTone.neutral,
                  icon: Icons.mood_outlined,
                ),
                StatusChip(
                  label: 'Ansiedade $_anxiety',
                  tone: AppStatusTone.warning,
                  icon: Icons.psychology_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(
              title: 'Estado geral',
              subtitle:
                  'Marque a intensidade que mais se aproxima de como você está agora.',
            ),
            const SizedBox(height: AppSpacing.sm),
            ScoreSliderField(
              label: 'Humor',
              value: _mood,
              onChanged: (v) => setState(() => _mood = v),
              lowLabel: 'Muito baixo',
              highLabel: 'Muito bom',
            ),
            ScoreSliderField(
              label: 'Ansiedade',
              value: _anxiety,
              onChanged: (v) => setState(() => _anxiety = v),
              lowLabel: 'Calmo',
              highLabel: 'Muito ansioso',
            ),
            ScoreSliderField(
              label: 'Energia',
              value: _energy,
              onChanged: (v) => setState(() => _energy = v),
              lowLabel: 'Exausto',
              highLabel: 'Muita energia',
            ),
            ScoreSliderField(
              label: 'Intensidade dos problemas',
              value: _problemIntensity,
              onChanged: (v) => setState(() => _problemIntensity = v),
              lowLabel: 'Leve',
              highLabel: 'Muito intenso',
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(
              title: 'Observações',
              subtitle:
                  'Use este espaço para registrar algo que ajude seu psicólogo a entender o contexto do dia.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEdit
                      ? 'Salvar alterações'
                      : 'Registrar check-in'),
            ),
          ],
        ),
      ),
    );
  }
}
