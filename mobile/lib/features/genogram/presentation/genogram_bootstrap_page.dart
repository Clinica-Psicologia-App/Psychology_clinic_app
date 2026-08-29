import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/genogram_bootstrap.dart';
import '../domain/genogram_layout.dart' show GEdge, GEdgeType;
import '../domain/genogram_relationship_input.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';

/// Tela do bootstrap: mostra os vínculos estruturais propostos a partir dos
/// papéis e deixa o terapeuta confirmar quais gravar. Escreve em
/// `genogram_relationships` via [GenogramRepository.createRelationship].
class GenogramBootstrapPage extends ConsumerStatefulWidget {
  const GenogramBootstrapPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<GenogramBootstrapPage> createState() =>
      _GenogramBootstrapPageState();
}

class _GenogramBootstrapPageState extends ConsumerState<GenogramBootstrapPage> {
  Set<int>? _accepted;
  // Escolha de lado dos avós: id → true (paterno) / false (materno).
  final Map<String, bool> _sides = {};
  bool _saving = false;

  static GenogramRelationshipType _mapType(GEdgeType t) => switch (t) {
        GEdgeType.spouse => GenogramRelationshipType.spouse,
        GEdgeType.exSpouse => GenogramRelationshipType.exSpouse,
        GEdgeType.parentChild => GenogramRelationshipType.parentChild,
      };

  static String _typeLabel(GEdgeType t) => switch (t) {
        GEdgeType.spouse => 'Casamento',
        GEdgeType.exSpouse => 'Ex-cônjuge',
        GEdgeType.parentChild => 'Pai/mãe → filho(a)',
      };

  Future<void> _commit(GBootstrapData data) async {
    final accepted = _accepted ?? const {};
    final sideEdges = grandparentSideEdges(
      plan: data.sidePlan,
      paternalById: _sides,
    );
    final total = accepted.length + sideEdges.length;
    if (total == 0 || data.clinicId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(genogramRepositoryProvider);

    Future<void> create(GEdge e) => repo.createRelationship(
          clinicId: data.clinicId!,
          patientId: data.patientId,
          input: GenogramRelationshipInput(
            personAId: e.a,
            personBId: e.b,
            relationshipType: _mapType(e.type),
          ),
        );

    try {
      for (final i in accepted) {
        await create(data.proposals[i].edge);
      }
      for (final e in sideEdges) {
        await create(e);
      }
      ref.invalidate(staffGenogramProvider);
      ref.invalidate(genogramBootstrapProvider(data.patientId));
      ref.invalidate(genogramDataForPatientProvider(data.patientId));
      ref.invalidate(genogramRelationshipsForPatientProvider(data.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$total vínculo(s) criado(s).')),
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(genogramBootstrapProvider(widget.patientId));

    return AppScaffold(
      title: 'Sugerir vínculos',
      accent: AppColors.turquoise,
      body: AsyncStateBody<GBootstrapData>(
        asyncValue: async,
        onRetry: () =>
            ref.invalidate(genogramBootstrapProvider(widget.patientId)),
        dataBuilder: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Nada a sugerir — os vínculos estruturais já estão '
                  'cadastrados, ou não há papéis suficientes (mãe, pai, '
                  'irmão, avós…) para inferir.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final proposals = data.proposals;
          final accepted =
              _accepted ??= {for (var i = 0; i < proposals.length; i++) i};
          final gps = data.sidePlan.grandparents;
          final total = accepted.length +
              grandparentSideEdges(plan: data.sidePlan, paternalById: _sides)
                  .length;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 4),
                      child: Text(
                        'Inferido dos papéis. Revise e confirme — nada é '
                        'gravado até você confirmar.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    if (proposals.isNotEmpty) ...[
                      _sectionLabel('Vínculos propostos'),
                      for (var i = 0; i < proposals.length; i++)
                        CheckboxListTile(
                          value: accepted.contains(i),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      accepted.add(i);
                                    } else {
                                      accepted.remove(i);
                                    }
                                  }),
                          title: Text(proposals[i].reason),
                          subtitle: Text(_typeLabel(proposals[i].edge.type)),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                    ],
                    if (data.sidePlan.isUsable && gps.isNotEmpty) ...[
                      _sectionLabel('Avós — de que lado?'),
                      for (final gp in gps) _grandparentTile(gp),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed:
                        _saving || total == 0 ? null : () => _commit(data),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    label: Text('Confirmar ($total)'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.xxs),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
      );

  Widget _grandparentTile(GGrandparentSideChoice gp) {
    final sel = _sides[gp.id];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gp.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xxs),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: true, label: Text('Paterno')),
              ButtonSegment(value: false, label: Text('Materno')),
            ],
            selected: sel == null ? <bool>{} : {sel},
            onSelectionChanged: _saving
                ? null
                : (s) => setState(() {
                      if (s.isEmpty) {
                        _sides.remove(gp.id);
                      } else {
                        _sides[gp.id] = s.first;
                      }
                    }),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
