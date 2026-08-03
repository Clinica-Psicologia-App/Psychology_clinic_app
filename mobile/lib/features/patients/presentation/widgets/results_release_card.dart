import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../providers/patients_providers.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Card de liberação dos resultados ao paciente (staff). Fica no fim do
/// Dashboard Clínico: o psicólogo valida as ativações e, quando pronto, libera
/// o acesso do paciente aos resultados/mapa mental.
class ResultsReleaseCard extends ConsumerStatefulWidget {
  const ResultsReleaseCard({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<ResultsReleaseCard> createState() => _ResultsReleaseCardState();
}

class _ResultsReleaseCardState extends ConsumerState<ResultsReleaseCard> {
  bool _busy = false;

  Future<void> _toggle(bool release) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(releaseResultsProvider.notifier).submit(
            patientId: widget.patientId,
            released: release,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(release
              ? 'Resultados liberados para o paciente.'
              : 'Liberação revogada.'),
        ),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patientAsync = ref.watch(patientDetailProvider(widget.patientId));
    final released = patientAsync.valueOrNull?.resultsReleased ?? false;
    final releasedAt = patientAsync.valueOrNull?.resultsReleasedAt;

    final accent = released ? AppColors.success : AppColors.warning;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      color: released
          ? AppColors.successContainer.withValues(alpha: 0.4)
          : AppColors.warningContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    released ? Icons.lock_open_outlined : Icons.lock_outline,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        released
                            ? 'Resultados liberados ao paciente'
                            : 'Resultados não liberados',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        released && releasedAt != null
                            ? 'Liberado em ${_fmt(releasedAt)} · o paciente vê '
                                'resultados e mapa mental.'
                            : 'Valide as ativações no perfil esquemático acima. '
                                'Ao liberar, o paciente passa a ver os resultados.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (released)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _toggle(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _busy
                    ? const _Spinner()
                    : const Icon(Icons.lock_outline),
                label: const Text('Revogar liberação'),
              )
            else
              FilledButton.icon(
                onPressed: _busy ? null : () => _toggle(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _busy
                    ? const _Spinner(light: true)
                    : const Icon(Icons.lock_open_outlined),
                label: const Text('Liberar resultados para o paciente'),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: light ? Colors.white : null,
      ),
    );
  }
}
