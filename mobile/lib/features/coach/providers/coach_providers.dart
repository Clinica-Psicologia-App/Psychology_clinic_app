import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coach_store.dart';
import '../domain/coach_tour.dart';
import '../presentation/widgets/coach_overlay.dart';

/// API de uso:
///
/// 1. Crie `GlobalKey`s nos widgets-alvo da pagina.
/// 2. No primeiro frame, chame:
///    `ref.read(coachControllerProvider.notifier).startTour(context, tour);`
/// 3. Um botao de ajuda pode rever o tour com:
///    `startTour(context, tour, force: true);`
final coachStoreProvider = Provider<CoachStore>((ref) => const CoachStore());

final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachSession?>((ref) {
  return CoachController(ref.read(coachStoreProvider));
});

class CoachSession {
  const CoachSession({
    required this.tour,
    required this.index,
  });

  final CoachTour tour;
  final int index;

  bool get isLast => index >= tour.steps.length - 1;
}

class CoachController extends StateNotifier<CoachSession?> {
  CoachController(this._store) : super(null);

  final CoachStore _store;
  OverlayEntry? _entry;

  Future<void> startTour(
    BuildContext context,
    CoachTour tour, {
    bool force = false,
  }) async {
    if (tour.steps.isEmpty) return;
    if (!force && await _store.hasSeen(tour.id)) return;
    if (!context.mounted) return;

    _removeEntry();
    state = CoachSession(tour: tour, index: 0);

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) {
        final session = state;
        if (session == null) return const SizedBox.shrink();
        return CoachOverlay(
          tour: session.tour,
          index: session.index,
          onNext: next,
          onSkip: skip,
        );
      },
    );
    overlay.insert(_entry!);
  }

  Future<void> next() async {
    final session = state;
    if (session == null) return;
    if (session.isLast) {
      await _complete(session.tour.id);
      return;
    }
    state = CoachSession(tour: session.tour, index: session.index + 1);
    _entry?.markNeedsBuild();
  }

  Future<void> skip() async {
    final session = state;
    if (session == null) return;
    await _complete(session.tour.id);
  }

  Future<void> reset(String tourId) => _store.reset(tourId);

  Future<void> _complete(String tourId) async {
    await _store.markSeen(tourId);
    _removeEntry();
    state = null;
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }
}
