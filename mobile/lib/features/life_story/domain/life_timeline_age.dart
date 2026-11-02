/// Idade de um acontecimento: ponto (uma idade) ou faixa (inicial e final).
///
/// A idade inicial mora em `age_at_event` (é ela que ordena a linha do tempo);
/// a final, opcional, em `age_to`. Só há faixa quando a final é maior que a
/// inicial — durações menores que um ano ficam na descrição.
class LifeAgeSpan {
  const LifeAgeSpan({this.start, this.end});

  final int? start;
  final int? end;

  bool get isRange {
    final s = start;
    final e = end;
    return s != null && e != null && e > s;
  }

  /// Rótulo completo: "15 anos", "1 ano" ou "15 a 18 anos".
  String? get label {
    final s = start;
    if (s == null) return null;
    if (isRange) return '$s a $end anos';
    return s == 1 ? '1 ano' : '$s anos';
  }

  /// Rótulo curto para a espinha: "15a" ou "15–18a".
  String? get shortLabel {
    final s = start;
    if (s == null) return null;
    return isRange ? '$s–${end}a' : '${s}a';
  }

  /// Mensagem de erro de preenchimento, ou `null` se está válido.
  static String? validate({int? start, int? end}) {
    if (end != null && start == null) {
      return 'Informe a idade inicial antes da final.';
    }
    if (start != null && end != null && end < start) {
      return 'A idade final não pode ser menor que a inicial.';
    }
    return null;
  }
}
