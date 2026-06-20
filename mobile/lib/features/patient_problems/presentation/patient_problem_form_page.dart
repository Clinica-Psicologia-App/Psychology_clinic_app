import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_problem.dart';
import '../domain/patient_problem_input.dart';
import '../domain/patient_problem_status.dart';
import '../providers/patient_problems_providers.dart';

class PatientProblemFormPage extends ConsumerStatefulWidget {
  const PatientProblemFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.problemId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? problemId;

  bool get isEdit => problemId != null;
  bool get isStaff => role != ProfileRole.patient;

  @override
  ConsumerState<PatientProblemFormPage> createState() =>
      _PatientProblemFormPageState();
}

class _PatientProblemFormPageState
    extends ConsumerState<PatientProblemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _intensityController = TextEditingController();

  DateTime? _identifiedAt;
  PatientProblemStatus _status = PatientProblemStatus.active;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _intensityController.dispose();
    super.dispose();
  }

  void _populateFromProblem(PatientProblem problem) {
    if (_loaded) return;
    _loaded = true;
    final input = PatientProblemInput.fromProblem(problem);
    _titleController.text = input.title;
    _descriptionController.text = input.description ?? '';
    _categoryController.text = input.category ?? '';
    _intensityController.text =
        input.intensity != null ? '${input.intensity}' : '';
    _identifiedAt = input.identifiedAt;
    _status = problem.status;
  }

  PatientProblemInput _buildInput() {
    final intensityText = _intensityController.text.trim();
    int? intensity;
    if (intensityText.isNotEmpty) {
      intensity = int.tryParse(intensityText);
    }

    return PatientProblemInput(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _categoryController.text,
      intensity: intensity,
      identifiedAt: widget.isStaff ? _identifiedAt : null,
      status: widget.isStaff && widget.isEdit ? _status : null,
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
      final repo = ref.read(patientProblemsRepositoryProvider);

      if (widget.isEdit) {
        if (widget.isStaff) {
          await repo.updateAsStaff(id: widget.problemId!, input: input);
        } else {
          await repo.updateAsPatient(id: widget.problemId!, input: input);
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

  Future<void> _pickIdentifiedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _identifiedAt ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 30)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _identifiedAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final problemAsync =
          ref.watch(patientProblemDetailProvider(widget.problemId!));
      return problemAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                patientProblemDetailProvider(widget.problemId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (problem) {
          if (problem == null) {
            return const AppScaffold(
              title: 'Problema',
              body: Center(child: Text('Problema não encontrado.')),
            );
          }
          _populateFromProblem(problem);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar problema' : 'Novo problema',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex.: Ansiedade em situações sociais',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                hintText: 'Ex.: Humor, Relacionamentos',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _intensityController,
              decoration: const InputDecoration(
                labelText: 'Intensidade (0-10)',
                hintText: '0 = leve, 10 = muito intenso',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 0 || n > 10) {
                  return 'Use um valor entre 0 e 10.';
                }
                return null;
              },
            ),
            if (widget.isStaff) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data de identificação (opcional)'),
                subtitle: Text(
                  _identifiedAt == null
                      ? 'Não definida'
                      : MaterialLocalizations.of(context).formatFullDate(
                          _identifiedAt!,
                        ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickIdentifiedDate,
                ),
              ),
              if (_identifiedAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _identifiedAt = null),
                    child: const Text('Remover data'),
                  ),
                ),
            ],
            if (widget.isStaff && widget.isEdit) ...[
              const SizedBox(height: 8),
              Text('Status', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PatientProblemStatus.values.map((s) {
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
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
                      : 'Registrar problema'),
            ),
          ],
        ),
      ),
    );
  }
}
