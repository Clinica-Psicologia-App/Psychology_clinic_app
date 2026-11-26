/// Ordem cronológica única da linha do tempo do infográfico (mais antigo
/// primeiro). Usada pelo infográfico do terapeuta e do próprio paciente.
///
/// Referência de cada acontecimento, em ordem de prioridade:
/// data exata → idade (`age_at_event`) → rótulo livre (ano de 4 dígitos ou
/// "N anos") → etapa da vida escrita no rótulo ("Infância", "Vida adulta"…,
/// como o formulário da psicóloga grava) → capítulo da vida. Sem nenhuma
/// referência, vai para o fim, pela ordem de cadastro.
///
/// Com data de nascimento, tudo vira idade e ordena numa sequência só.
/// Sem nascimento não dá para misturar data com idade: primeiro vêm os que têm
/// data ou ano (por data), depois os que têm só idade ou capítulo (por idade).
/// Desempate sempre pelo cadastro (`created_at` crescente) e, por fim, pela
/// posição original (a ordenação é estável).
class TimelineRef {
  const TimelineRef({
    this.eventDate,
    this.ageAtEvent,
    this.periodLabel,
    this.lifeChapter,
    this.createdAt,
  });

  final DateTime? eventDate;
  final int? ageAtEvent;
  final String? periodLabel;
  final String? lifeChapter;
  final DateTime? createdAt;
}

/// Idade típica de cada capítulo da vida (só para ordenar). Inclui
/// `early_years`, que não existe na lista de rótulos exibidos.
const _chapterAge = <String, double>{
  'birth': 0,
  'early_years': 3,
  'childhood': 6,
  'adolescence': 15,
  'adulthood': 30,
  'maturity': 55,
  'today': 99,
};

/// Nome de etapa escrito no rótulo (`period_label`) → capítulo equivalente.
/// A "Etapa da vida" do formulário da psicóloga é gravada assim.
const _stageChapters = <String, String>{
  'nascimento': 'birth',
  'primeiros anos': 'early_years',
  'infância': 'childhood',
  'adolescência': 'adolescence',
  'vida adulta': 'adulthood',
  'maturidade': 'maturity',
  'hoje': 'today',
  'momento atual': 'today',
};

final _yearRe = RegExp(r'(?<!\d)(?:19|20)\d{2}(?!\d)');
final _ageRe = RegExp(r'(?<!\d)(\d{1,3})\s*anos?(?![a-zà-ú])',
    caseSensitive: false);

class _Key {
  const _Key(this.group, this.value, this.createdAt, this.index);
  final int group; // 0 = datado, 1 = só idade/capítulo, 2 = sem referência
  final double value;
  final DateTime? createdAt;
  final int index;
}

_Key _keyOf(TimelineRef r, DateTime? birth, int index) {
  // 1) data exata; 2) idade; 3) rótulo livre; 4) etapa no rótulo; 5) capítulo.
  DateTime? date = r.eventDate;
  double? age = r.ageAtEvent?.toDouble();
  final label = r.periodLabel?.trim() ?? '';
  if (date == null && age == null) {
    final y = _yearRe.firstMatch(label);
    if (y != null) {
      date = DateTime(int.parse(y.group(0)!), 7, 1);
    } else {
      final a = _ageRe.firstMatch(label);
      if (a != null) age = int.parse(a.group(1)!).toDouble();
    }
  }
  final chapter = _stageChapters[label.toLowerCase()] ?? r.lifeChapter;
  age ??= date == null ? _chapterAge[chapter ?? ''] : null;

  if (birth != null) {
    if (date != null) {
      return _Key(0, date.difference(birth).inDays / 365.25, r.createdAt, index);
    }
    if (age != null) return _Key(0, age, r.createdAt, index);
  } else {
    if (date != null) {
      return _Key(0, date.millisecondsSinceEpoch.toDouble(), r.createdAt, index);
    }
    if (age != null) return _Key(1, age, r.createdAt, index);
  }
  return _Key(2, 0, r.createdAt, index);
}

int _compareKeys(_Key a, _Key b) {
  var c = a.group.compareTo(b.group);
  if (c != 0) return c;
  c = a.value.compareTo(b.value);
  if (c != 0) return c;
  final x = a.createdAt;
  final y = b.createdAt;
  if (x != null && y != null) {
    c = x.compareTo(y);
    if (c != 0) return c;
  }
  return a.index.compareTo(b.index);
}

/// Devolve uma cópia de [items] em ordem cronológica (mais antigo primeiro).
List<T> sortChronologically<T>(
  List<T> items,
  TimelineRef Function(T item) refOf, {
  DateTime? birth,
}) {
  final keyed = [
    for (var i = 0; i < items.length; i++)
      (items[i], _keyOf(refOf(items[i]), birth, i)),
  ]..sort((a, b) => _compareKeys(a.$2, b.$2));
  return [for (final k in keyed) k.$1];
}

/// Comparador de dois acontecimentos (0 só se empatam em tudo).
int compareChronologically(TimelineRef a, TimelineRef b, {DateTime? birth}) =>
    _compareKeys(_keyOf(a, birth, 0), _keyOf(b, birth, 0));
