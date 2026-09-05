import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_attention.dart';
import 'package:terapia_esquema/features/patients/domain/patient_data_completion.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_list_tile.dart';

const _completion = PatientDataCompletion(
  patientId: 'p1',
  perfil: true,
  queixa: true,
  areas: true,
  historia: false,
  familia: false,
  questionarios: false,
);

Future<void> _pump(
  WidgetTester tester, {
  PatientAttention? attention,
  VoidCallback? onQuickAction,
  bool showEmail = false,
  bool active = true,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: PatientListTile(
        patient: Patient(
          id: 'p1',
          fullName: 'Roberto Silva',
          email: 'roberto@example.com',
          isActive: active,
        ),
        attention: attention,
        checkinMissingDays: attention == null ? 2 : 999,
        dataCompletion: _completion,
        showEmail: showEmail,
        onQuickAction: onQuickAction,
        onTap: () {},
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('paciente em dia mostra a semana e não mostra botão de ação',
      (tester) async {
    await _pump(tester);

    expect(find.text('5/7'), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // anel de preenchimento
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.phone_rounded), findsNothing);
  });

  testWidgets('paciente em atenção mostra o motivo e o botão da ação',
      (tester) async {
    var taps = 0;
    await _pump(
      tester,
      attention: const PatientAttention(
        kind: PatientAttentionKind.noCheckin,
        label: 'Nunca fez check-in',
      ),
      onQuickAction: () => taps++,
    );

    expect(find.text('Nunca fez check-in'), findsOneWidget);
    // Selo (estado) e botão (ação) usam ícones diferentes de propósito.
    expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    expect(find.byIcon(Icons.phone_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.phone_rounded));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('sem callback de ação, a linha volta a mostrar a seta',
      (tester) async {
    await _pump(
      tester,
      attention: const PatientAttention(
        kind: PatientAttentionKind.emptyData,
        label: 'Sem avaliação inicial',
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsNothing);
  });

  testWidgets('e-mail só aparece quando a busca está ativa', (tester) async {
    await _pump(tester);
    expect(find.text('roberto@example.com'), findsNothing);

    await _pump(tester, showEmail: true);
    expect(find.text('roberto@example.com'), findsOneWidget);
  });

  testWidgets('paciente inativo não mostra anel nem semana', (tester) async {
    await _pump(tester, active: false);

    expect(find.text('Acompanhamento encerrado'), findsOneWidget);
    expect(find.text('Inativo'), findsOneWidget);
    expect(find.text('50'), findsNothing);
  });
}
