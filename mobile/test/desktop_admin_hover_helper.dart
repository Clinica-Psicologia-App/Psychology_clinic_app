// Conferência do hover das linhas do admin desktop (usada por E1 a E4).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';

/// Passa o mouse no item (linha, menu, trilha, índice) que contém [cell] e tira
/// o mouse, amostrando o fundo quadro a quadro. O fundo (composto sobre os da
/// tela) nunca pode sair do intervalo entre o repouso e o realce (sair é a
/// "piscada"), o item não se move, o conteúdo não reanima e o cursor é o de
/// clique. Com
/// [reduced], a troca é instantânea.
Future<void> expectSmoothRowHover(
  WidgetTester tester,
  Finder cell, {
  bool reduced = false,
  List<Color>? bases, // fundos sobre os quais compor (padrão: os claros)
}) async {
  final row = find
      .ancestor(of: cell, matching: find.byType(AnimatedContainer))
      .first;
  final box =
      find.descendant(of: row, matching: find.byType(DecoratedBox)).first;
  final tokens = DesktopAdminTokens.of(tester.element(row));
  Color fill() =>
      (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color!;

  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await tester.pump();

  final rect = tester.getRect(row);
  final rest = fill();

  Future<void> sweep(Offset to) async {
    final from = fill();
    await mouse.moveTo(to);
    await tester.pump();
    final samples = <Color>[fill()];
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      samples.add(fill());
      expect(tester.getRect(row), rect, reason: 'o item mudou de lugar');
      for (final e in tester
          .widgetList<FadeTransition>(find.byKey(daContentEntranceKey))) {
        expect(e.opacity.value, 1.0,
            reason: 'a entrada do conteúdo reexecutou');
      }
    }
    final end = samples.last;
    for (final base in bases ?? [tokens.rz, tokens.bg, tokens.side]) {
      final a = Color.alphaBlend(from, base);
      final b = Color.alphaBlend(end, base);
      expect(a, isNot(b), reason: 'o hover não mudou o fundo');
      for (final s in samples) {
        final c = Color.alphaBlend(s, base);
        for (final (v, x, y) in [
          (c.r, a.r, b.r),
          (c.g, a.g, b.g),
          (c.b, a.b, b.b),
        ]) {
          const tol = 1.5 / 255;
          expect(v, greaterThanOrEqualTo((x < y ? x : y) - tol),
              reason: 'piscada escura no meio do hover');
          expect(v, lessThanOrEqualTo((x > y ? x : y) + tol),
              reason: 'piscada clara no meio do hover');
        }
      }
    }
    if (reduced) {
      expect(samples.first, end, reason: 'animou com reduzir movimento');
    } else {
      // Há fade: meio do caminho aos 60 ms, ainda indo aos 100, pronto aos 160.
      expect(samples[3], isNot(from));
      expect(samples[3], isNot(end));
      expect(samples[5], isNot(end), reason: 'rápido demais (< 120 ms)');
      expect(samples[8], end, reason: 'lento demais (> 150 ms)');
    }
  }

  await sweep(tester.getCenter(cell));
  expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click);
  await sweep(Offset.zero);
  expect(Color.alphaBlend(fill(), tokens.rz),
      Color.alphaBlend(rest, tokens.rz));
  await mouse.removePointer();
}
