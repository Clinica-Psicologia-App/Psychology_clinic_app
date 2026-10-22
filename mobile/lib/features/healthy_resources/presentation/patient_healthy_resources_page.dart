import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/healthy_resource_catalog.dart';
import '../domain/healthy_resources.dart';
import '../providers/healthy_resources_providers.dart';

class StaffPatientHealthyResourcesPage extends ConsumerWidget {
  const StaffPatientHealthyResourcesPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthyResourcesProvider(patientId));

    return async.when(
      loading: () => AppCanopyScaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: patientId,
                pageTitle: 'RECURSOS SAUDÁVEIS',
                role: role,
                accentColor: AppColors.cyan,
              ),
            ),
            const SliverFillRemaining(
              child: Center(child: BrandLoader()),
            ),
          ],
        ),
      ),
      error: (e, _) => AppCanopyScaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: patientId,
                pageTitle: 'RECURSOS SAUDÁVEIS',
                role: role,
                accentColor: AppColors.cyan,
              ),
            ),
            SliverFillRemaining(
              child: Center(
                child: FilledButton(
                  onPressed: () =>
                      ref.invalidate(healthyResourcesProvider(patientId)),
                  child: const Text('Tentar novamente'),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (initial) => _ResourcesForm(
        role: role,
        patientId: patientId,
        initial: initial,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ResourcesForm extends ConsumerStatefulWidget {
  const _ResourcesForm({
    required this.role,
    required this.patientId,
    required this.initial,
  });

  final ProfileRole role;
  final String patientId;
  final HealthyResources initial;

  @override
  ConsumerState<_ResourcesForm> createState() => _ResourcesFormState();
}

class _ResourcesFormState extends ConsumerState<_ResourcesForm> {
  late Set<String> _selected;
  late List<String> _custom;
  late TextEditingController _obsCtrl;
  final _customCtrl = TextEditingController();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initial.selectedPredefined);
    _custom = List<String>.from(widget.initial.customResources);
    _obsCtrl = TextEditingController(text: widget.initial.observations ?? '');
    _obsCtrl.addListener(_markDirty);
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _markDirty() => setState(() => _dirty = true);

  void _togglePredefined(String id) {
    setState(() {
      _dirty = true;
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _addCustom() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) return;
    if (_custom.any((c) => c.toLowerCase() == text.toLowerCase())) {
      _customCtrl.clear();
      return;
    }
    setState(() {
      _dirty = true;
      _custom.add(text);
      _customCtrl.clear();
    });
  }

  void _removeCustom(String item) => setState(() {
        _dirty = true;
        _custom.remove(item);
      });

  Future<void> _save() async {
    final data = HealthyResources(
      selectedPredefined: _selected.toList(),
      customResources: _custom,
      observations: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );
    await ref
        .read(saveHealthyResourcesProvider(widget.patientId).notifier)
        .save(data);
    if (!mounted) return;
    final saveAsync =
        ref.read(saveHealthyResourcesProvider(widget.patientId));
    if (saveAsync.hasError) {
      showErrorBanner(context, saveAsync.error ?? 'Erro ao salvar.');
    } else {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recursos salvos com sucesso.')),
      );
    }
  }

  int _countSelected(HealthyResourceCategory cat) =>
      cat.items.where((i) => _selected.contains(i.id)).length;

  @override
  Widget build(BuildContext context) {
    final saving =
        ref.watch(saveHealthyResourcesProvider(widget.patientId)).isLoading;
    final theme = Theme.of(context);
    final totalSelected = _selected.length + _custom.length;

    return AppCanopyScaffold(
      floatingActionButton: _dirty
          ? FloatingActionButton.extended(
              onPressed: saving ? null : _save,
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Salvando…' : 'Salvar recursos'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PatientContextHeader(
              patientId: widget.patientId,
              pageTitle: 'RECURSOS SAUDÁVEIS',
              role: widget.role,
              accentColor: AppColors.cyan,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: AppPageHeader(
                title: 'Recursos Saudáveis',
                subtitle:
                    'Selecione os recursos positivos já presentes na vida do paciente.',
                icon: Icons.spa_outlined,
                metadata: [
                  if (totalSelected > 0)
                    Chip(
                      label: Text('$totalSelected selecionado(s)'),
                      avatar: const Icon(Icons.check_circle_outline, size: 16),
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.md),

              // ── Categorias predefinidas ──────────────────────────────────
              for (final cat in kHealthyResourceCatalog)
                _CategoryCard(
                  category: cat,
                  selectedCount: _countSelected(cat),
                  selected: _selected,
                  onToggle: _togglePredefined,
                  theme: theme,
                ),

              // ── Recurso personalizado ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _SectionCard(
                  title: 'Recurso personalizado',
                  subtitle: 'Adicione um recurso que não está na lista acima.',
                  icon: Icons.add_circle_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customCtrl,
                              maxLength: 80,
                              decoration: const InputDecoration(
                                hintText: 'Descreva o recurso…',
                                counterText: '',
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _addCustom(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton.icon(
                            onPressed: _addCustom,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cyan,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_custom.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final c in _custom)
                              Chip(
                                label: Text(
                                  c,
                                  style: TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.cyan,
                                ),
                                onDeleted: () => _removeCustom(c),
                                backgroundColor:
                                    AppColors.cyan.withValues(alpha: 0.1),
                                side: BorderSide(
                                  color: AppColors.cyan.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Observações ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _SectionCard(
                  title: 'Observações clínicas',
                  subtitle: 'Campo opcional — contexto adicional sobre os recursos identificados.',
                  icon: Icons.notes_outlined,
                  child: TextField(
                    controller: _obsCtrl,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Observações sobre os recursos identificados…',
                      alignLabelWithHint: true,
                      isDense: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 96),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selectedCount,
    required this.selected,
    required this.onToggle,
    required this.theme,
  });

  final HealthyResourceCategory category;
  final int selectedCount;
  final Set<String> selected;
  final void Function(String id) onToggle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: _SectionCard(
        title: category.label,
        subtitle: selectedCount > 0
            ? '$selectedCount selecionado(s)'
            : 'Nenhum selecionado',
        subtitleColor: selectedCount > 0 ? AppColors.cyan : null,
        icon: Icons.category_outlined,
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in category.items)
              _ResourceChip(
                label: item.label,
                isSelected: selected.contains(item.id),
                onTap: () => onToggle(item.id),
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor ??
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : theme.dividerColor.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 14, color: AppColors.cyan),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.cyan
                    : theme.textTheme.bodySmall?.color,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
