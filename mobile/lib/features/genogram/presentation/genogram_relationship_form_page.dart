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
import '../domain/genogram_data.dart';
import '../domain/genogram_relationship.dart';
import '../domain/genogram_relationship_input.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';

class GenogramRelationshipFormPage extends ConsumerStatefulWidget {
  const GenogramRelationshipFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.relationshipId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? relationshipId;

  bool get isEdit => relationshipId != null;

  @override
  ConsumerState<GenogramRelationshipFormPage> createState() =>
      _GenogramRelationshipFormPageState();
}

class _GenogramRelationshipFormPageState
    extends ConsumerState<GenogramRelationshipFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _personAId;
  String? _personBId;
  GenogramRelationshipType _type = GenogramRelationshipType.other;
  bool _isSensitive = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _populate(GenogramRelationship relationship) {
    if (_loaded) return;
    _loaded = true;
    final input = GenogramRelationshipInput.fromRelationship(relationship);
    _personAId = input.personAId;
    _personBId = input.personBId;
    _type = input.relationshipType;
    _notesController.text = input.notes ?? '';
    _isSensitive = input.isSensitive;
  }

  GenogramRelationshipInput _buildInput() {
    return GenogramRelationshipInput(
      personAId: _personAId ?? '',
      personBId: _personBId ?? '',
      relationshipType: _type,
      notes: _notesController.text,
      isSensitive: _isSensitive,
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
      final repo = ref.read(genogramRepositoryProvider);

      if (widget.isEdit) {
        await repo.updateRelationship(
          id: widget.relationshipId!,
          input: input,
        );
      } else {
        final ctx = await repo.resolvePatientContext(
          patientId: widget.patientId,
        );
        await repo.createRelationship(
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
      final relAsync = ref.watch(
        genogramRelationshipDetailProvider(widget.relationshipId!),
      );
      return relAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                genogramRelationshipDetailProvider(widget.relationshipId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (rel) {
          if (rel == null) {
            return const AppScaffold(
              title: 'Relação',
              body: Center(child: Text('Relação não encontrada.')),
            );
          }
          _populate(rel);
          return _buildWithData();
        },
      );
    }

    return _buildWithData();
  }

  Widget _buildWithData() {
    final genogramAsync = widget.role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(
                role: widget.role,
                patientId: widget.patientId!,
              ),
            ),
          );

    return genogramAsync.when(
      loading: () => const AppScaffold(
        title: 'Carregando...',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => AppScaffold(
        title: 'Erro',
        body: Center(
          child: FilledButton(
            onPressed: () {
              if (widget.role == ProfileRole.patient) {
                ref.read(myGenogramProvider.notifier).refresh();
              } else {
                ref.invalidate(
                  staffGenogramProvider(
                    StaffGenogramContext(
                      role: widget.role,
                      patientId: widget.patientId!,
                    ),
                  ),
                );
              }
            },
            child: const Text('Tentar novamente'),
          ),
        ),
      ),
      data: (data) {
        if (data.people.length < 2) {
          return const AppScaffold(
            title: 'Nova relação',
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cadastre pelo menos duas pessoas antes de registrar uma relação.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return _buildForm(data);
      },
    );
  }

  Widget _buildForm(GenogramData data) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar relação' : 'Nova relação',
      body: MotionReveal(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              AppPageHeader(
                icon: Icons.link_outlined,
                title: widget.isEdit ? 'Editar relação' : 'Nova relação',
                subtitle:
                    'Descreva a natureza da conexão entre duas pessoas do genograma.',
                metadata: [
                  StatusChip(
                    label: _type.label,
                    tone: AppStatusTone.info,
                    icon: Icons.sync_alt_outlined,
                  ),
                  StatusChip(
                    label: _isSensitive ? 'Sensível' : 'Visível',
                    tone: _isSensitive
                        ? AppStatusTone.warning
                        : AppStatusTone.neutral,
                    icon: _isSensitive
                        ? Icons.lock_outline
                        : Icons.visibility_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Pessoas envolvidas',
                subtitle:
                    'Selecione as duas pessoas conectadas por esta relação.',
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _personAId,
                decoration: const InputDecoration(labelText: 'Pessoa A *'),
                items: _personItems(data),
                onChanged: (v) => setState(() => _personAId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _personBId,
                decoration: const InputDecoration(labelText: 'Pessoa B *'),
                items: _personItems(data, excludeId: _personAId),
                onChanged: (v) => setState(() => _personBId = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Natureza da relação',
                subtitle:
                    'Escolha o tipo de vínculo e registre observações clínicas quando necessário.',
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<GenogramRelationshipType>(
                initialValue: _type,
                decoration:
                    const InputDecoration(labelText: 'Tipo da relação *'),
                items: GenogramRelationshipType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Descreva como essa relação costuma ser. Ex.: '
                      'fonte de apoio, aceitação e segurança; fonte de '
                      'crítica; fonte de rejeição; fonte de proteção '
                      'excessiva; fonte de exigência excessiva.',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conteúdo sensível'),
                subtitle: const Text(
                  'Oculta detalhes na visualização principal e exibe aviso antes do acesso.',
                ),
                value: _isSensitive,
                onChanged: (v) => setState(() => _isSensitive = v),
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
                        : 'Registrar relação'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _personItems(
    GenogramData data, {
    String? excludeId,
  }) {
    return data.people
        .where((p) => p.id != excludeId)
        .map(
          (p) => DropdownMenuItem(
            value: p.id,
            child: Text(p.displayName),
          ),
        )
        .toList();
  }
}
