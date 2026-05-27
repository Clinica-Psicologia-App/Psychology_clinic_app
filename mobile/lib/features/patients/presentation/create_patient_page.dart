import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/create_patient_request.dart';
import '../domain/psychologist_option.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';

class CreatePatientPage extends ConsumerStatefulWidget {
  const CreatePatientPage({super.key, required this.role});

  final ProfileRole role;

  @override
  ConsumerState<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends ConsumerState<CreatePatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedPsychologistId;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.role == ProfileRole.admin;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final psychologistsAsync = _isAdmin
        ? ref.watch(psychologistsOptionsProvider)
        : const AsyncValue<List<PsychologistOption>>.data([]);

    final psychologistId = _isAdmin
        ? _selectedPsychologistId
        : profile?.id;

    return AppScaffold(
      title: 'Novo paciente',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail de login *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpfController,
              decoration: const InputDecoration(
                labelText: 'CPF',
                border: OutlineInputBorder(),
                hintText: 'Opcional',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _birthDate == null
                    ? 'Data de nascimento (opcional)'
                    : 'Nascimento: ${_formatDate(_birthDate!)}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickBirthDate,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha inicial *',
                border: OutlineInputBorder(),
                helperText: 'Mínimo 8 caracteres (acesso do paciente ao app)',
              ),
              obscureText: true,
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'Senha com pelo menos 8 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha *',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 16),
              Text(
                'Psicólogo responsável *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              psychologistsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'Não foi possível carregar psicólogos.',
                ),
                data: (options) {
                  if (options.isEmpty) {
                    return const Text(
                      'Nenhum psicólogo ativo na clínica.',
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPsychologistId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: options
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.displayLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPsychologistId = v),
                    validator: (v) =>
                        v == null ? 'Selecione o psicólogo' : null,
                  );
                },
              ),
            ] else if (profile != null) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Psicólogo responsável'),
                subtitle: Text(profile.fullName),
                leading: const Icon(Icons.psychology_outlined),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting || profile == null || psychologistId == null
                  ? null
                  : () => _submit(profile, psychologistId),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cadastrar paciente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit(UserProfile profile, String psychologistId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final patient = await ref.read(createPatientProvider.notifier).submit(
            CreatePatientRequest(
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              responsiblePsychologistId: psychologistId,
              phone: _phoneController.text,
              cpf: _cpfController.text,
              birthDate: _birthDate,
            ),
          );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Paciente cadastrado'),
          content: Text(
            '${patient.fullName} foi criado com sucesso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go(PatientRoutes.detail(widget.role, patient.id));
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
