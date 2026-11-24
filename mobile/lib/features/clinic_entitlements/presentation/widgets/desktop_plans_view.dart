import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/brand_loading.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../clinics/domain/clinic_summary.dart';
import '../../data/admin_entitlements_repository.dart';
import '../../providers/admin_entitlements_providers.dart';

/// Planos e permissões em desktop: mestre-detalhe (clínicas à esquerda,
/// módulos com liga/desliga à direita). Mesma gravação do celular.
class DesktopPlansView extends ConsumerStatefulWidget {
  const DesktopPlansView({super.key, required this.clinics});

  final List<ClinicSummary> clinics;

  @override
  ConsumerState<DesktopPlansView> createState() => _DesktopPlansViewState();
}

class _DesktopPlansViewState extends ConsumerState<DesktopPlansView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final clinics = widget.clinics;
    final selected = clinics.isEmpty
        ? null
        : clinics.firstWhere((c) => c.id == _selectedId,
            orElse: () => clinics.first);
    final listW = m.size == DesktopAdminSize.desktop
        ? 380.0
        : (m.tablet ? 270.0 : 320.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Liberação de módulos',
              style: daText(context, t,
                  size: m.size == DesktopAdminSize.desktop ? 16 : 15,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Text(
                'Ligue ou desligue módulos por clínica. O que estiver ligado '
                'fica disponível para os psicólogos daquela clínica, '
                'independentemente do plano.',
                style: daText(context, t, color: t.tx2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.rz,
                border: Border.all(color: t.bd2),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: selected == null
                  ? Center(
                      child: Text('Nenhuma clínica cadastrada.',
                          style: daText(context, t, color: t.tx3)))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: listW,
                          decoration: BoxDecoration(
                            color: t.bg,
                            border: Border(right: BorderSide(color: t.bd2)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 38,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: t.side,
                                  border: Border(
                                      bottom: BorderSide(color: t.bd2)),
                                ),
                                child: Text('Clínicas e consultórios',
                                    style: daText(context, t,
                                        size: 12,
                                        weight: FontWeight.w500,
                                        color: t.tx3)),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    for (final c in clinics)
                                      _Item(
                                        clinic: c,
                                        m: m,
                                        selected: c.id == selected.id,
                                        onTap: () =>
                                            setState(() => _selectedId = c.id),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            layoutBuilder: (cur, prev) => Stack(
                              alignment: Alignment.topLeft,
                              children: [...prev, if (cur != null) cur],
                            ),
                            child: _Detail(
                                key: ValueKey(selected.id), clinic: selected),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatefulWidget {
  const _Item({
    required this.clinic,
    required this.m,
    required this.selected,
    required this.onTap,
  });

  final ClinicSummary clinic;
  final DesktopAdminMetrics m;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final c = widget.clinic;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: widget.m.row),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.sel
                : (_hover ? t.hov : Colors.transparent),
            border: Border(
              bottom: BorderSide(color: t.bd),
              left: BorderSide(
                  color: widget.selected ? t.tq : Colors.transparent,
                  width: 3),
            ),
          ),
          child: Row(
            children: [
              const DaIconBox(Icons.apartment_outlined,
                  color: DesktopAdminTokens.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, weight: FontWeight.w600)),
                    Text(
                        '${c.userCount} profissional(is) · ${c.patientCount} paciente(s)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, size: 12, color: t.tx3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 16,
                  color: t.tx3.withValues(
                      alpha: widget.selected || _hover ? 1 : 0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({super.key, required this.clinic});

  final ClinicSummary clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final ent = ref.watch(clinicEntitlementsAdminProvider(clinic.id));
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: m.size == DesktopAdminSize.desktop ? 40 : 28,
          vertical: 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.bd))),
                child: Row(children: [
                  const DaIconBox(Icons.apartment_outlined,
                      color: DesktopAdminTokens.purple, size: 44, radius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clinic.name,
                            style: daText(context, t,
                                size: 17, weight: FontWeight.w600)),
                        Text(
                            '${clinic.userCount} profissional(is) · ${clinic.patientCount} paciente(s)',
                            style: daText(context, t, color: t.tx3)),
                      ],
                    ),
                  ),
                ]),
              ),
              ent.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(24), child: BrandLoader()),
                error: (e, _) => Text(
                    e.toString().replaceFirst(
                        RegExp(r'^AppException\([^)]*\):\s*'), ''),
                    style: daText(context, t, color: t.err)),
                data: (map) => Column(
                  children: [
                    for (final f in adminManageableFeatures)
                      _FeatureRow(
                        clinicId: clinic.id,
                        feature: f,
                        value: map[f.key] ?? true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends ConsumerStatefulWidget {
  const _FeatureRow({
    required this.clinicId,
    required this.feature,
    required this.value,
  });

  final String clinicId;
  final AdminFeatureDef feature;
  final bool value;

  @override
  ConsumerState<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends ConsumerState<_FeatureRow> {
  late bool _value = widget.value;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _FeatureRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _value = widget.value;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final v = !_value;
    setState(() {
      _value = v;
      _busy = true;
    });
    try {
      await ref.read(entitlementMutationProvider.notifier).setEnabled(
            clinicId: widget.clinicId,
            feature: widget.feature,
            enabled: v,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _value = !v); // desfaz o otimismo
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e
              .toString()
              .replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Container(
      constraints: BoxConstraints(minHeight: m.row),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.feature.name,
                    style: daText(context, t, weight: FontWeight.w600)),
                Text(widget.feature.description,
                    style: daText(context, t, size: 12, color: t.tx3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DaSwitch(
            value: _value,
            semantics: widget.feature.name,
            tablet: m.tablet,
            onChanged: _busy ? null : _toggle,
          ),
        ],
      ),
    );
  }
}
