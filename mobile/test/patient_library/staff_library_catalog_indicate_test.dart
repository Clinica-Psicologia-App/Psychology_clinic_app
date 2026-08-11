import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work_full.dart';
import 'package:terapia_esquema/features/patient_library/presentation/staff_library_catalog_page.dart';
import 'package:terapia_esquema/features/patient_library/providers/staff_library_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

/// Antes, indicar uma obra exigia entrar na ficha de detalhe. Agora o card
/// da lista já tem o botão "Indicar" — este teste garante que ele funciona
/// sem depender de navegação, e que a capa aparece no card.
void main() {
  const work = LibraryWorkFull(
    id: 'work-1',
    displayTitle: 'A viagem de Chihiro',
    workType: 'Filme',
    year: 2001,
    primarySchema: 'Fracasso',
    coverUrl: 'https://example.com/chihiro.jpg',
  );

  Future<void> pumpCatalog(
    WidgetTester tester, {
    required _RecordingIndicateNotifier notifier,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sem `async`: resolve no mesmo frame, sem passar pelo estado de
          // loading do AsyncStateBody (LoadingSkeletonList, que assume
          // altura generosa e não é o alvo deste teste).
          libraryCatalogProvider.overrideWith((ref, filter) => [work]),
          librarySchemasProvider.overrideWith((ref) => const []),
          indicateWorkProvider.overrideWith(() => notifier),
        ],
        child: const MaterialApp(
          home: StaffLibraryCatalogPage(
            role: ProfileRole.psychologist,
            patientId: 'patient-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('card mostra a capa e o botão Indicar, sem precisar abrir a ficha',
      (tester) async {
    final notifier = _RecordingIndicateNotifier();
    await pumpCatalog(tester, notifier: notifier);

    expect(find.text('A viagem de Chihiro'), findsOneWidget);
    expect(find.text('Indicar'), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add_check_outlined), findsOneWidget);

    // Nenhuma navegação disparada ainda.
    expect(notifier.calls, isEmpty);
  });

  testWidgets('tocar em Indicar abre o sheet e confirma sem sair do catálogo',
      (tester) async {
    final notifier = _RecordingIndicateNotifier();
    await pumpCatalog(tester, notifier: notifier);

    await tester.tap(find.text('Indicar'));
    await tester.pumpAndSettle();

    expect(find.text('Indicar “A viagem de Chihiro”'), findsOneWidget);

    await tester.tap(find.text('Confirmar indicação'));
    await tester.pumpAndSettle();

    expect(notifier.calls, hasLength(1));
    expect(notifier.calls.single.patientId, 'patient-1');
    expect(notifier.calls.single.workId, 'work-1');

    // Voltou para o catálogo (o sheet fechou) — não navegou para a ficha.
    // "Biblioteca clínica" aparece duas vezes de propósito: no AppBar e no
    // cabeçalho da página.
    expect(find.text('Biblioteca clínica'), findsNWidgets(2));
    expect(find.text('Obra indicada ao paciente.'), findsOneWidget);
  });
}

class _IndicateCall {
  const _IndicateCall({required this.patientId, required this.workId});
  final String patientId;
  final String workId;
}

class _RecordingIndicateNotifier extends IndicateWorkNotifier {
  final calls = <_IndicateCall>[];

  @override
  Future<void> build() async {}

  @override
  Future<void> submit({
    required String patientId,
    required String workId,
    String? objective,
    String? scope,
  }) async {
    calls.add(_IndicateCall(patientId: patientId, workId: workId));
    state = const AsyncValue.data(null);
  }
}
