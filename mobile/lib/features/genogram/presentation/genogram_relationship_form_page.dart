import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_relationship.dart';
import '../domain/genogram_relationship_input.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

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
  bool _isAdoptive = false;
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
    _isAdoptive = input.isAdoptive;
    _isSensitive = input.isSensitive;
  }

  GenogramRelationshipInput _buildInput() {
    return GenogramRelationshipInput(
      personAId: _personAId ?? '',
      personBId: _personBId ?? '',
      relationshipType: _type,
      notes: _notesController.text,
      isAdoptive: _isAdoptive,
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
        loading: () => const AppCanopyScaffold(body: BrandLoader()),
        error: (_, __) => AppCanopyScaffold(
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
            return const AppCanopyScaffold(
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
      loading: () => const AppCanopyScaffold(body: BrandLoader()),
      error: (_, __) => AppCanopyScaffold(
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
          return AppCanopyScaffold(
            body: Column(
              children: [
                _RelationshipFormHeader(
                  isEdit: widget.isEdit,
                  typeName: _type.label,
                  isSensitive: _isSensitive,
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Cadastre pelo menos duas pessoas antes de registrar uma relação.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildForm(data);
      },
    );
  }

  Widget _buildForm(GenogramData data) {
    return AppCanopyScaffold(
      body: MotionReveal(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _RelationshipFormHeader(
                isEdit: widget.isEdit,
                typeName: _type.label,
                isSensitive: _isSensitive,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(
                        title: 'Pessoas envolvidas',
                        subtitle:
                            'Selecione as duas pessoas conectadas por esta relação.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _personAId,
                        decoration:
                            const InputDecoration(labelText: 'Pessoa A *'),
                        items: _personItems(data),
                        onChanged: (v) => setState(() => _personAId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _personBId,
                        decoration:
                            const InputDecoration(labelText: 'Pessoa B *'),
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
                        decoration: const InputDecoration(
                            labelText: 'Tipo da relação *'),
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
                      if (_type == GenogramRelationshipType.parentChild) ...[
                        const SizedBox(height: AppSpacing.xs),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Filiação adotiva'),
                          subtitle: const Text(
                            'Desenha a descida tracejada no genograma (padrão McGoldrick).',
                          ),
                          value: _isAdoptive,
                          onChanged: (v) => setState(() => _isAdoptive = v),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          hintText:
                              'Descreva como essa relação costuma ser. Ex.: '
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(widget.isEdit
                                ? 'Salvar alterações'
                                : 'Registrar relação'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

// ── Form hero header ──────────────────────────────────────────────────────────

class _RelationshipFormHeader extends StatelessWidget {
  const _RelationshipFormHeader({
    required this.isEdit,
    required this.typeName,
    required this.isSensitive,
  });

  final bool isEdit;
  final String typeName;
  final bool isSensitive;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063530), Color(0xFF1D9E75)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Genograma',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
            // Icon + title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSensitive ? Icons.lock_outline : Icons.link_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Editar relação' : 'Nova relação',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          typeName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
