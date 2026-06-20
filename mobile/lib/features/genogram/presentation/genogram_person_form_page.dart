import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_gender.dart';
import '../domain/genogram_person.dart';
import '../domain/genogram_person_input.dart';
import '../providers/genogram_providers.dart';

class GenogramPersonFormPage extends ConsumerStatefulWidget {
  const GenogramPersonFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.personId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? personId;

  bool get isEdit => personId != null;

  @override
  ConsumerState<GenogramPersonFormPage> createState() =>
      _GenogramPersonFormPageState();
}

class _GenogramPersonFormPageState
    extends ConsumerState<GenogramPersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _deathYearController = TextEditingController();
  final _notesController = TextEditingController();

  GenogramGender? _gender;
  bool _isDeceased = false;
  bool _isSensitive = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _relationshipController.dispose();
    _birthYearController.dispose();
    _deathYearController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populate(GenogramPerson person) {
    if (_loaded) return;
    _loaded = true;
    final input = GenogramPersonInput.fromPerson(person);
    _fullNameController.text = input.fullName;
    _nicknameController.text = input.nickname ?? '';
    _relationshipController.text = input.relationshipToPatient ?? '';
    _birthYearController.text =
        input.birthYear != null ? '${input.birthYear}' : '';
    _deathYearController.text =
        input.deathYear != null ? '${input.deathYear}' : '';
    _notesController.text = input.notes ?? '';
    _gender = input.gender;
    _isDeceased = input.isDeceased;
    _isSensitive = input.isSensitive;
  }

  int? _parseYear(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  GenogramPersonInput _buildInput() {
    return GenogramPersonInput(
      fullName: _fullNameController.text,
      nickname: _nicknameController.text,
      relationshipToPatient: _relationshipController.text,
      gender: _gender,
      birthYear: _parseYear(_birthYearController.text),
      deathYear: _parseYear(_deathYearController.text),
      isDeceased: _isDeceased,
      notes: _notesController.text,
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
      final repo = ref.read(genogramRepositoryProvider);

      if (widget.isEdit) {
        await repo.updatePerson(id: widget.personId!, input: input);
      } else {
        final ctx = await repo.resolvePatientContext(
          patientId: widget.patientId,
        );
        await repo.createPerson(
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

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final personAsync =
          ref.watch(genogramPersonDetailProvider(widget.personId!));
      return personAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                genogramPersonDetailProvider(widget.personId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (person) {
          if (person == null) {
            return const AppScaffold(
              title: 'Pessoa',
              body: Center(child: Text('Pessoa não encontrada.')),
            );
          }
          _populate(person);
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return AppScaffold(
      title: widget.isEdit ? 'Editar pessoa' : 'Nova pessoa',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: 'Apelido'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relação com o paciente',
                hintText: 'Ex.: Mãe, Pai, Avó',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GenogramGender?>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gênero'),
              items: [
                const DropdownMenuItem<GenogramGender?>(
                  value: null,
                  child: Text('Não informado'),
                ),
                ...GenogramGender.values.map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.label),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthYearController,
              decoration: const InputDecoration(
                labelText: 'Ano de nascimento',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Falecido'),
              value: _isDeceased,
              onChanged: (v) => setState(() => _isDeceased = v),
            ),
            if (_isDeceased) ...[
              TextFormField(
                controller: _deathYearController,
                decoration: const InputDecoration(
                  labelText: 'Ano de falecimento',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Conteúdo sensível'),
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
                      widget.isEdit ? 'Salvar alterações' : 'Adicionar pessoa'),
            ),
          ],
        ),
      ),
    );
  }
}
