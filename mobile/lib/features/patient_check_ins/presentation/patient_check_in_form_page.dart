import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_scaffold.dart';
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
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
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
              body: Center(child: Text('Check-in não encontrado.')),
            );
          }
          if (!checkIn.isEditableToday) {
            return AppScaffold(
              title: 'Check-in',
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Como você está agora? Use as escalas de 0 (muito baixo) a 10 (muito alto).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
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
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.isEdit ? 'Salvar alterações' : 'Registrar check-in'),
          ),
        ],
      ),
    );
  }
}
