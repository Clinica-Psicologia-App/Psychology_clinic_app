import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/authorized_timeline_entry.dart';
import '../providers/own_infographic_providers.dart';

/// Infográfico do próprio paciente. Por enquanto só a linha do tempo, e apenas
/// com os acontecimentos que o psicólogo autorizou.
class OwnInfographicPage extends ConsumerWidget {
  const OwnInfographicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientIdAsync = ref.watch(myPatientIdProvider);

    return patientIdAsync.when(
      loading: () => const AppCanopyScaffold(body: Center(child: BrandLoader())),
      error: (_, __) => const AppScaffold(
        title: 'Meu infográfico',
        accent: AppColors.cyan,
        body: Center(child: Text('Erro ao identificar paciente.')),
      ),
      data: (patientId) {
        final timeline = ref.watch(ownInfographicTimelineProvider(patientId));
        return AppCanopyScaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PatientContextHeader(
                  patientId: patientId,
                  pageTitle: 'MEU INFOGRÁFICO',
                  role: ProfileRole.patient,
                  accentColor: AppColors.cyan,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: timeline.when(
                  loading: () => const BrandLoader(),
                  error: (_, __) => Center(
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(ownInfographicTimelineProvider),
                      child: const Text('Tentar de novo'),
                    ),
                  ),
                  data: (entries) => entries.isEmpty
                      ? const _EmptyTimeline()
                      : _TimelineList(entries: entries),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Seu psicólogo ainda não liberou acontecimentos para este '
          'infográfico.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.entries});

  final List<AuthorizedTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: entries.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Text(
            'Linha do tempo',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
          );
        }
        final e = entries[i - 1];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.periodLabel.isNotEmpty)
                Text(
                  e.periodLabel.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.turquoise),
                ),
              if (e.periodLabel.isNotEmpty) const SizedBox(height: 4),
              Text(e.title,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      height: 1.35)),
            ],
          ),
        );
      },
    );
  }
}
