import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/genogram_layout.dart' show GEdgeType;
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
    if (accepted.isEmpty || data.clinicId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(genogramRepositoryProvider);
    try {
      for (final i in accepted) {
        final p = data.proposals[i];
        await repo.createRelationship(
          clinicId: data.clinicId!,
          patientId: data.patientId,
          input: GenogramRelationshipInput(
            personAId: p.edge.a,
            personBId: p.edge.b,
            relationshipType: _mapType(p.edge.type),
          ),
        );
      }
      ref.invalidate(staffGenogramProvider);
      ref.invalidate(genogramBootstrapProvider(data.patientId));
      ref.invalidate(genogramRelationshipsForPatientProvider(data.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${accepted.length} vínculo(s) criado(s).')),
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
          final proposals = data.proposals;
          if (proposals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Nada a sugerir — os vínculos estruturais já estão '
                  'cadastrados, ou não há papéis suficientes (mãe, pai, '
                  'irmão…) para inferir.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final accepted =
              _accepted ??= {for (var i = 0; i < proposals.length; i++) i};

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: Text(
                  'Inferido dos papéis registrados. Revise e confirme o que '
                  'faz sentido — nada é gravado até você confirmar.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: proposals.length,
                  itemBuilder: (context, i) {
                    final p = proposals[i];
                    return CheckboxListTile(
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
                      title: Text(p.reason),
                      subtitle: Text(_typeLabel(p.edge.type)),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: _saving || accepted.isEmpty
                        ? null
                        : () => _commit(data),
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
                    label: Text('Confirmar (${accepted.length})'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
