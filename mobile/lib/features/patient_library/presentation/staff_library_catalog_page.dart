import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/library_work_full.dart';
import '../providers/staff_library_providers.dart';
import 'patient_library_routes.dart';
import 'widgets/indicate_work_sheet.dart';
import 'widgets/library_cover.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Catálogo clínico (psicólogo): busca + filtro por esquema + indicação.
class StaffLibraryCatalogPage extends ConsumerStatefulWidget {
  const StaffLibraryCatalogPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<StaffLibraryCatalogPage> createState() =>
      _StaffLibraryCatalogPageState();
}

class _StaffLibraryCatalogPageState
    extends ConsumerState<StaffLibraryCatalogPage> {
  String? _schema;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filter =
        LibraryCatalogFilter(schema: _schema, query: _query.trim().isEmpty ? null : _query.trim());
    final worksAsync = ref.watch(libraryCatalogProvider(filter));
    final schemasAsync = ref.watch(librarySchemasProvider);

    return AppScaffold(
      title: 'Biblioteca clínica',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppPageHeader(
              icon: Icons.movie_filter_outlined,
              title: 'Biblioteca clínica',
              subtitle:
                  'Filmes e séries por esquema, para indicar ao paciente a partir '
                  'da conceitualização.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por título…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceTint,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: schemasAsync.maybeWhen(
              data: (schemas) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SchemaChip(
                    label: 'Todos',
                    selected: _schema == null,
                    onTap: () => setState(() => _schema = null),
                  ),
                  for (final s in schemas)
                    _SchemaChip(
                      label: s,
                      selected: _schema == s,
                      onTap: () => setState(() => _schema = s),
                    ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncStateBody<List<LibraryWorkFull>>(
              asyncValue: worksAsync,
              onRetry: () => ref.invalidate(libraryCatalogProvider(filter)),
              emptyMessage: 'Nenhuma obra para este filtro.',
              emptyIcon: Icons.movie_outlined,
              dataBuilder: (works) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: works.length,
                itemBuilder: (_, i) => _WorkTile(
                  work: works[i],
                  patientId: widget.patientId,
                  onTap: () => context.push(
                    PatientLibraryRoutes.staffWork(
                      role: widget.role,
                      patientId: widget.patientId,
                      workId: works[i].id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaChip extends StatelessWidget {
  const _SchemaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Gradiente de fallback da capa por tipo de obra — mesma paleta usada na
/// ficha de detalhe, só para a capa não ficar cinza quando a obra não tem
/// `cover_url` cadastrada.
const _kSeriesCoverFallback = [Color(0xFF2E7D6B), Color(0xFF11808F)];
const _kMovieCoverFallback = [Color(0xFF3B2F8F), Color(0xFF7C6A9C)];

class _WorkTile extends StatelessWidget {
  const _WorkTile({
    required this.work,
    required this.patientId,
    required this.onTap,
  });

  final LibraryWorkFull work;
  final String patientId;
  final VoidCallback onTap;

  bool get _isSeries =>
      work.workType == 'Série' || work.workType == 'Minissérie';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      work.workType,
      if (work.year != null) '${work.year}',
      if (work.intensity != null) 'Intensidade ${work.intensity}',
    ].join(' · ');

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 64,
                  child: LibraryCover(
                    gradient:
                        _isSeries ? _kSeriesCoverFallback : _kMovieCoverFallback,
                    url: work.coverUrl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(work.displayTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(meta,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    if (work.primarySchema != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            label: work.primarySchema!,
                            tone: AppStatusTone.info,
                            icon: Icons.psychology_outlined,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Indica direto do card — não exige mais entrar na
                    // ficha da obra para liberar ao paciente.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => showIndicateWorkSheet(
                          context: context,
                          patientId: patientId,
                          work: work,
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.playlist_add_check_outlined,
                          size: 15,
                        ),
                        label: const Text('Indicar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
