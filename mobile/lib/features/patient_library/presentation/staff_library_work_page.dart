import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/library_work.dart';
import '../domain/library_work_full.dart';
import '../providers/staff_library_providers.dart';
import 'widgets/indicate_work_sheet.dart';
import 'widgets/library_cover.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Ficha clínica completa (camada do psicólogo) + ação de indicar ao paciente.
class StaffLibraryWorkPage extends ConsumerWidget {
  const StaffLibraryWorkPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.workId,
  });

  final ProfileRole role;
  final String patientId;
  final String workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(libraryWorkProvider(workId));

    return AppScaffold(
      title: 'Ficha da obra',
      accent: AppColors.cyan,
      body: AsyncStateBody<LibraryWorkFull?>(
        asyncValue: async,
        onRetry: () => ref.invalidate(libraryWorkProvider(workId)),
        dataBuilder: (work) {
          if (work == null) {
            return const Center(child: Text('Obra não encontrada.'));
          }
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _Header(work: work),
                  if ((work.synopsis ?? '').isNotEmpty)
                    _TextCard(title: 'Sinopse clínica', text: work.synopsis!),
                  _ListCard('Quando indicar', work.psychologist.whenToIndicate,
                      Icons.flag_outlined),
                  _ListCard('Objetivos terapêuticos',
                      work.psychologist.objectives, Icons.adjust_outlined),
                  _ListCard(
                      'Focos de observação',
                      work.psychologist.observationFocus,
                      Icons.visibility_outlined),
                  _ChipsCard('Mobilizações emocionais',
                      work.psychologist.emotionalMobilizations),
                  _ListCard(
                      'Cuidados clínicos e alertas',
                      work.psychologist.clinicalCautions,
                      Icons.warning_amber_outlined,
                      accent: AppColors.warning),
                  _ChipsCard('Modos ativados', work.psychologist.schemaModes),
                  _ListCard(
                      'Intervenções sugeridas',
                      work.psychologist.sessionInterventions,
                      Icons.handyman_outlined),
                  _ListCard('Perguntas para sessão',
                      work.psychologist.sessionQuestions, Icons.help_outline),
                  if ((work.psychologist.clinicalNote ?? '').isNotEmpty)
                    _TextCard(
                        title: 'Observação clínica',
                        text: work.psychologist.clinicalNote!),
                  _PatientPreview(layer: work.patientLayer),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  onPressed: () => _openIndicate(context, work),
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: const Text('Indicar ao paciente'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openIndicate(BuildContext context, LibraryWorkFull work) {
    showIndicateWorkSheet(context: context, patientId: patientId, work: work);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.work});
  final LibraryWorkFull work;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      work.workType,
      if (work.year != null) '${work.year}',
      if (work.duration != null) work.duration!,
      if (work.seasons != null) '${work.seasons} temporada(s)',
      if (work.rating != null) work.rating!,
    ].join(' · ');

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(work.displayTitle,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy)),
        if ((work.originalTitle ?? '').isNotEmpty)
          Text(work.originalTitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        const SizedBox(height: 6),
        Text(meta,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (work.primarySchema != null)
              _Tag(work.primarySchema!, AppColors.purple, primary: true),
            for (final s in work.associatedSchemas) _Tag(s, AppColors.cyan),
            if (work.intensity != null)
              _Tag('Intensidade ${work.intensity}', AppColors.warning),
          ],
        ),
      ],
    );

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 120,
                child: LibraryCover(
                  gradient: const [Color(0xFF3B2F8F), Color(0xFF11808F)],
                  url: work.coverUrl,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: info),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color, {this.primary = false});
  final String label;
  final Color color;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: primary ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border:
            primary ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: primary ? FontWeight.w800 : FontWeight.w600)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, this.icon, this.accent});
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accent ?? AppColors.cyan),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.navy)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard(this.title, this.items, this.icon, {this.accent});
  final String title;
  final List<String> items;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return _SectionCard(
      title: title,
      icon: icon,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent ?? AppColors.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(it,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipsCard extends StatelessWidget {
  const _ChipsCard(this.title, this.items);
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: title,
      icon: Icons.label_outline,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final it in items) _Tag(it, AppColors.turquoise)],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: Icons.notes_outlined,
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.45)),
    );
  }
}

class _PatientPreview extends StatelessWidget {
  const _PatientPreview({required this.layer});
  final LibraryPatientLayer layer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if ((layer.before ?? '').isEmpty &&
        layer.during.isEmpty &&
        layer.after.isEmpty) {
      return const SizedBox.shrink();
    }
    return _SectionCard(
      title: 'O que o paciente verá',
      icon: Icons.visibility_outlined,
      accent: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((layer.before ?? '').isNotEmpty) ...[
            Text('Antes de assistir',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(layer.before!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
          ],
          if (layer.after.isNotEmpty)
            Text('${layer.after.length} pergunta(s) no "depois de assistir"',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
