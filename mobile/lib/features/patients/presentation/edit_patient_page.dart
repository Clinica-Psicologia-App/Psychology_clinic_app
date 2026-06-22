import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../domain/psychologist_option.dart';
import '../domain/update_patient_request.dart';
import '../providers/patients_providers.dart';

class EditPatientPage extends ConsumerStatefulWidget {
  const EditPatientPage({
    super.key,
    required this.patient,
    required this.role,
  });

  final Patient patient;
  final ProfileRole role;

  @override
  ConsumerState<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends ConsumerState<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _occupation;
  late final TextEditingController _stateBirth;
  late final TextEditingController _countryBirth;
  late final TextEditingController _religiousOrientation;
  late final TextEditingController _ethnicGroup;

  DateTime? _birthDate;
  String? _gender;
  String? _relationshipStatus;
  String? _educationLevel;
  String? _sexualOrientation;
  bool? _hasChildren;
  String? _responsiblePsychologistId;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _fullName = TextEditingController(text: p.fullName);
    _phone = TextEditingController(text: p.phone ?? '');
    _occupation = TextEditingController(text: p.occupation ?? '');
    _stateBirth = TextEditingController(text: p.stateBirth ?? '');
    _countryBirth = TextEditingController(text: p.countryBirth ?? '');
    _religiousOrientation =
        TextEditingController(text: p.religiousOrientation ?? '');
    _ethnicGroup = TextEditingController(text: p.ethnicGroup ?? '');
    _birthDate = p.birthDate;
    _gender = p.gender;
    _relationshipStatus = p.relationshipStatus;
    _educationLevel = p.educationLevel;
    _sexualOrientation = p.sexualOrientation;
    _hasChildren = p.hasChildren;
    _responsiblePsychologistId = p.responsiblePsychologistId;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _occupation.dispose();
    _stateBirth.dispose();
    _countryBirth.dispose();
    _religiousOrientation.dispose();
    _ethnicGroup.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdatePatientRequest(
      patientId: widget.patient.id,
      fullName: _fullName.text.trim(),
      phone: _phone.text,
      birthDate: _birthDate,
      gender: _gender,
      relationshipStatus: _relationshipStatus,
      educationLevel: _educationLevel,
      occupation: _occupation.text,
      stateBirth: _stateBirth.text,
      countryBirth: _countryBirth.text,
      religiousOrientation: _religiousOrientation.text,
      ethnicGroup: _ethnicGroup.text,
      sexualOrientation: _sexualOrientation,
      hasChildren: _hasChildren,
      responsiblePsychologistId: _responsiblePsychologistId,
    );

    try {
      await ref.read(updatePatientProvider.notifier).submit(request);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updatePatientProvider);
    final psychologistsAsync = ref.watch(psychologistsOptionsProvider);
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);

    return AppScaffold(
      title: 'Editar paciente',
      body: MotionReveal(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (updateState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MaterialBanner(
                    content: Text(
                      updateState.error is AppException
                          ? (updateState.error as AppException).message
                          : 'Erro ao salvar. Tente novamente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => ref.invalidate(updatePatientProvider),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),

              const _SectionHeader('Dados pessoais'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'Nome completo *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Birth date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _birthDate != null
                        ? loc.formatFullDate(_birthDate!)
                        : 'Selecionar data',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _birthDate == null
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _DropdownField<String>(
                label: 'Gênero',
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Feminino')),
                  DropdownMenuItem(value: 'male', child: Text('Masculino')),
                  DropdownMenuItem(
                      value: 'non_binary', child: Text('Não binário')),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                  DropdownMenuItem(
                      value: 'nao_informado', child: Text('Não informado')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 16),

              _DropdownField<String>(
                label: 'Estado civil',
                value: _relationshipStatus,
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Solteiro(a)')),
                  DropdownMenuItem(value: 'married', child: Text('Casado(a)')),
                  DropdownMenuItem(
                      value: 'divorced', child: Text('Divorciado(a)')),
                  DropdownMenuItem(value: 'widowed', child: Text('Viúvo(a)')),
                  DropdownMenuItem(
                      value: 'stable_union', child: Text('União estável')),
                  DropdownMenuItem(
                      value: 'nao_informado', child: Text('Não informado')),
                ],
                onChanged: (v) => setState(() => _relationshipStatus = v),
              ),
              const SizedBox(height: 16),

              _DropdownField<String>(
                label: 'Escolaridade',
                value: _educationLevel,
                items: const [
                  DropdownMenuItem(
                      value: 'elementary', child: Text('Ensino fundamental')),
                  DropdownMenuItem(
                      value: 'high_school', child: Text('Ensino médio')),
                  DropdownMenuItem(
                      value: 'undergraduate', child: Text('Ensino superior')),
                  DropdownMenuItem(
                      value: 'graduate', child: Text('Pós-graduação')),
                  DropdownMenuItem(
                      value: 'nao_informado', child: Text('Não informado')),
                ],
                onChanged: (v) => setState(() => _educationLevel = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _occupation,
                decoration: const InputDecoration(
                  labelText: 'Ocupação',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Origem'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stateBirth,
                decoration: const InputDecoration(
                  labelText: 'Estado de nascimento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _countryBirth,
                decoration: const InputDecoration(
                  labelText: 'País de nascimento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader('Diversidade'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _religiousOrientation,
                decoration: const InputDecoration(
                  labelText: 'Orientação religiosa',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ethnicGroup,
                decoration: const InputDecoration(
                  labelText: 'Grupo étnico',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              _DropdownField<String>(
                label: 'Orientação sexual',
                value: _sexualOrientation,
                items: const [
                  DropdownMenuItem(
                      value: 'heterosexual', child: Text('Heterossexual')),
                  DropdownMenuItem(
                      value: 'homosexual', child: Text('Homossexual')),
                  DropdownMenuItem(value: 'bisexual', child: Text('Bissexual')),
                  DropdownMenuItem(value: 'asexual', child: Text('Assexual')),
                  DropdownMenuItem(
                      value: 'pansexual', child: Text('Pansexual')),
                  DropdownMenuItem(
                      value: 'nao_informado', child: Text('Não informado')),
                ],
                onChanged: (v) => setState(() => _sexualOrientation = v),
              ),
              const SizedBox(height: 16),

              _DropdownField<bool>(
                label: 'Filhos',
                value: _hasChildren,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Sim')),
                  DropdownMenuItem(value: false, child: Text('Não')),
                ],
                onChanged: (v) => setState(() => _hasChildren = v),
              ),
              const SizedBox(height: 24),

              if (widget.role == ProfileRole.platformAdmin ||
                  widget.role == ProfileRole.psychologist) ...[
                const _SectionHeader('Responsabilidade'),
                const SizedBox(height: 12),
                psychologistsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text(
                    'Não foi possível carregar os psicólogos.',
                  ),
                  data: (psychologists) => _PsychologistDropdown(
                    psychologists: psychologists,
                    selectedId: _responsiblePsychologistId,
                    onChanged: (id) =>
                        setState(() => _responsiblePsychologistId = id),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              FilledButton(
                onPressed: updateState.isLoading ? null : _submit,
                child: updateState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar alterações'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _PsychologistDropdown extends StatelessWidget {
  const _PsychologistDropdown({
    required this.psychologists,
    required this.selectedId,
    required this.onChanged,
  });

  final List<PsychologistOption> psychologists;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'Psicólogo responsável',
        border: OutlineInputBorder(),
      ),
      items: psychologists
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.fullName),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
