import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/therapy_resource.dart';
import '../domain/therapy_resource_input.dart';
import '../domain/therapy_resource_type.dart';
import '../providers/therapy_resources_providers.dart';

class TherapyResourceFormPage extends ConsumerStatefulWidget {
  const TherapyResourceFormPage({
    super.key,
    required this.role,
    required this.patientId,
    this.resourceId,
  });

  final ProfileRole role;
  final String patientId;
  final String? resourceId;

  bool get isEdit => resourceId != null;

  @override
  ConsumerState<TherapyResourceFormPage> createState() =>
      _TherapyResourceFormPageState();
}

class _TherapyResourceFormPageState
    extends ConsumerState<TherapyResourceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  TherapyResourceType _type = TherapyResourceType.exercise;
  bool _isActive = true;
  bool _loaded = false;

  TherapyResourceFormArgs get _args => TherapyResourceFormArgs(
        role: widget.role,
        patientId: widget.patientId,
        resourceId: widget.resourceId,
      );

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _populateFromResource(TherapyResource resource) {
    if (_loaded) return;
    _loaded = true;
    final input = TherapyResourceInput.fromResource(resource);
    _titleController.text = input.title;
    _descriptionController.text = input.description ?? '';
    _urlController.text = input.url ?? '';
    _type = input.type;
    _isActive = input.isActive;
  }

  TherapyResourceInput _buildInput() {
    return TherapyResourceInput(
      title: _titleController.text,
      type: _type,
      description: _descriptionController.text,
      url: _urlController.text,
      isActive: _isActive,
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

    try {
      await ref.read(therapyResourceFormProvider(_args).notifier).save(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit ? 'Material atualizado.' : 'Material cadastrado.',
          ),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException
                ? userMessageFor(e)
                : 'Não foi possível salvar o material.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final resourceAsync =
          ref.watch(therapyResourceDetailProvider(widget.resourceId!));
      return resourceAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Material',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                therapyResourceDetailProvider(widget.resourceId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (resource) {
          if (resource == null) {
            return const AppScaffold(
              title: 'Material',
              body: Center(child: Text('Material não encontrado.')),
            );
          }
          _populateFromResource(resource);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final formState = ref.watch(therapyResourceFormProvider(_args));
    final saving = formState.isLoading;

    return AppScaffold(
      title: widget.isEdit ? 'Editar material' : 'Novo material',
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
                icon: _type.icon,
                title: widget.isEdit ? 'Editar material' : 'Novo material',
                subtitle:
                    'Cadastre recursos terapêuticos para orientar exercícios, leituras, vídeos ou links de apoio ao paciente.',
                metadata: [
                  StatusChip(
                    label: _type.label,
                    tone: AppStatusTone.info,
                    icon: _type.icon,
                  ),
                  StatusChip(
                    label: _isActive ? 'Ativo' : 'Oculto',
                    tone: _isActive
                        ? AppStatusTone.completed
                        : AppStatusTone.neutral,
                    icon: _isActive
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Identificação',
                subtitle:
                    'Defina o nome e o tipo do material para facilitar busca e liberação.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex.: Exercício de registro emocional',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<TherapyResourceType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de material',
                ),
                items: TherapyResourceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(type.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _type = value);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Orientação de uso',
                subtitle:
                    'Explique quando o paciente deve acessar o material e inclua um link quando houver.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                  hintText: 'Oriente quando e como o paciente deve usar.',
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Link do material',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                validator: (v) {
                  final clean = v?.trim();
                  if (clean == null || clean.isEmpty) return null;
                  final uri = Uri.tryParse(clean);
                  if (uri == null ||
                      (uri.scheme != 'http' && uri.scheme != 'https') ||
                      uri.host.trim().isEmpty) {
                    return 'Informe um link válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Disponibilidade',
                subtitle:
                    'Materiais ocultos permanecem cadastrados, mas não aparecem para novas liberações.',
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Material ativo'),
                subtitle: Text(
                  _isActive
                      ? 'Aparece na biblioteca da clínica.'
                      : 'Fica oculto para novas liberações.',
                ),
                value: _isActive,
                onChanged: saving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  saving
                      ? 'Salvando...'
                      : widget.isEdit
                          ? 'Salvar alterações'
                          : 'Cadastrar material',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
