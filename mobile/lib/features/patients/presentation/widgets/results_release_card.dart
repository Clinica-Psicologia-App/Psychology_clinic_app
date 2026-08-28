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
    // Só a liberação exige confirmação — revogar é uma ação de segurança,
    // não precisa de trava.
    if (release && !await _confirmRelease(context)) return;
    if (!mounted) return;
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
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        released && releasedAt != null
                            ? 'Liberado em ${_fmt(releasedAt)} · o paciente vê '
                                'resultados e mapa mental.'
                            : 'Valide as ativações no perfil esquemático acima. '
                                'Ao liberar, o paciente passa a ver os resultados.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                icon: _busy ? const _Spinner() : const Icon(Icons.lock_outline),
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

/// Aviso compacto no topo do Dashboard Clínico: some assim que o psicólogo
/// libera. Existe porque o card completo ([ResultsReleaseCard]) fica no fim
/// da página — sem isso, é fácil terminar de revisar o caso e esquecer o
/// último passo, que é só um clique.
class PendingResultsReleaseBanner extends ConsumerStatefulWidget {
  const PendingResultsReleaseBanner({
    super.key,
    required this.patientId,
    required this.structuredResultCount,
  });

  final String patientId;
  final int structuredResultCount;

  @override
  ConsumerState<PendingResultsReleaseBanner> createState() =>
      _PendingResultsReleaseBannerState();
}

class _PendingResultsReleaseBannerState
    extends ConsumerState<PendingResultsReleaseBanner> {
  bool _busy = false;

  Future<void> _release() async {
    if (_busy) return;
    if (!await _confirmRelease(context)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(releaseResultsProvider.notifier).submit(
            patientId: widget.patientId,
            released: true,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultados liberados para o paciente.')),
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

    if (released || widget.structuredResultCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resultado pronto, aguardando liberação',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onWarningContainer,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy ? null : _release,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              backgroundColor: AppColors.warning,
            ),
            child: _busy
                ? const _Spinner(light: true)
                : const Text('Liberar'),
          ),
        ],
      ),
    );
  }
}

/// Trava de liberação: exige confirmação explícita, não uma detecção
/// automática de "revisão". Nenhum dado hoje distingue "0 esquemas ativados
/// porque ninguém revisou" de "0 esquemas ativados porque não há nenhum
/// acima do limiar" — então o sinal confiável é a própria ação deliberada do
/// psicólogo no momento de liberar, não um rastro passivo no banco.
Future<bool> _confirmRelease(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const _ReleaseConfirmationDialog(),
  );
  return confirmed ?? false;
}

class _ReleaseConfirmationDialog extends StatefulWidget {
  const _ReleaseConfirmationDialog();

  @override
  State<_ReleaseConfirmationDialog> createState() =>
      _ReleaseConfirmationDialogState();
}

class _ReleaseConfirmationDialogState
    extends State<_ReleaseConfirmationDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Liberar resultados?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O paciente passa a ver os resultados dos questionários e o '
            'mapa mental.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _checked = !_checked),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: (v) => setState(() => _checked = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Text(
                      'Confirmo que revisei as ativações do perfil '
                      'esquemático deste paciente.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              _checked ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Confirmar liberação'),
        ),
      ],
    );
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
