import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../patient_check_ins/presentation/widgets/patient_check_in_widgets.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_timeline_event.dart';
import '../domain/patient_timeline_event_input.dart';
import '../providers/patient_timeline_providers.dart';

class PatientTimelineEventFormPage extends ConsumerStatefulWidget {
  const PatientTimelineEventFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.eventId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? eventId;

  bool get isEdit => eventId != null;

  @override
  ConsumerState<PatientTimelineEventFormPage> createState() =>
      _PatientTimelineEventFormPageState();
}

class _PatientTimelineEventFormPageState
    extends ConsumerState<PatientTimelineEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _periodLabelController = TextEditingController();
  final _categoryController = TextEditingController();

  DateTime? _eventDate;
  bool _includeEmotionalImpact = false;
  int _emotionalImpact = 5;
  bool _isSensitive = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _periodLabelController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _populateFromEvent(PatientTimelineEvent event) {
    if (_loaded) return;
    _loaded = true;
    final input = PatientTimelineEventInput.fromEvent(event);
    _titleController.text = input.title;
    _descriptionController.text = input.description ?? '';
    _periodLabelController.text = input.periodLabel ?? '';
    _categoryController.text = input.category ?? '';
    _eventDate = input.eventDate;
    _isSensitive = input.isSensitive;
    if (input.emotionalImpact != null) {
      _includeEmotionalImpact = true;
      _emotionalImpact = input.emotionalImpact!;
    }
  }

  PatientTimelineEventInput _buildInput() {
    return PatientTimelineEventInput(
      title: _titleController.text,
      description: _descriptionController.text,
      eventDate: _eventDate,
      periodLabel: _periodLabelController.text,
      category: _categoryController.text,
      emotionalImpact: _includeEmotionalImpact ? _emotionalImpact : null,
      isSensitive: _isSensitive,
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
      final repo = ref.read(patientTimelineRepositoryProvider);

      if (widget.isEdit) {
        await repo.update(id: widget.eventId!, input: input);
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

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 80)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final eventAsync =
          ref.watch(patientTimelineEventDetailProvider(widget.eventId!));
      return eventAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                patientTimelineEventDetailProvider(widget.eventId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (event) {
          if (event == null) {
            return const AppScaffold(
              title: 'Evento',
              body: Center(child: Text('Evento não encontrado.')),
            );
          }
          _populateFromEvent(event);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar evento' : 'Novo evento',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex.: Mudança de cidade',
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
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data do evento (opcional)'),
              subtitle: Text(
                _eventDate == null
                    ? 'Não definida'
                    : MaterialLocalizations.of(context).formatFullDate(
                        _eventDate!,
                      ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _pickEventDate,
              ),
            ),
            if (_eventDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _eventDate = null),
                  child: const Text('Remover data'),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _periodLabelController,
              decoration: const InputDecoration(
                labelText: 'Período textual (opcional)',
                hintText: 'Ex.: Infância, Adolescência, 2020',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                hintText: 'Ex.: Família, Trabalho, Saúde',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Informar impacto emocional'),
              subtitle: const Text('Escala de 0 a 10'),
              value: _includeEmotionalImpact,
              onChanged: (v) => setState(() => _includeEmotionalImpact = v),
            ),
            if (_includeEmotionalImpact) ...[
              ScoreSliderField(
                label: 'Impacto emocional',
                value: _emotionalImpact,
                onChanged: (v) => setState(() => _emotionalImpact = v),
                lowLabel: 'Baixo',
                highLabel: 'Alto',
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Conteúdo sensível'),
              subtitle: const Text(
                'Destaca o evento na linha do tempo para atenção na leitura.',
              ),
              value: _isSensitive,
              onChanged: (v) => setState(() => _isSensitive = v),
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
                      widget.isEdit ? 'Salvar alterações' : 'Registrar evento'),
            ),
          ],
        ),
      ),
    );
  }
}
