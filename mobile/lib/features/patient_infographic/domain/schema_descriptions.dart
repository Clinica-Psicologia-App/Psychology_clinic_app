/// Descrições curtas dos Esquemas Iniciais Desadaptativos (Young), para o
/// infográfico. Determinístico: usado quando o esquema ativado não traz uma
/// descrição própria. A chave é o nome normalizado (sem acento, minúsculo).
///
/// Não é diagnóstico — é psicoeducação de apoio, sempre sob revisão do
/// profissional.
String? schemaDescriptionFor(String name) {
  final key = _normalize(name);
  for (final entry in _byKeyword.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return null;
}

const Map<String, String> _byKeyword = {
  'abandono':
      'Medo de perder vínculos e de que pessoas importantes não permaneçam por perto.',
  'instabilidade':
      'Sensação de que o apoio e a conexão podem faltar a qualquer momento.',
  'desconfianca':
      'Expectativa de ser magoada, usada ou humilhada; tende a se proteger.',
  'abuso':
      'Expectativa de ser magoada, usada ou humilhada; tende a se proteger.',
  'privacao':
      'Sente que suas necessidades emocionais nem sempre foram compreendidas ou atendidas.',
  'isolamento':
      'Sentimento de ser diferente e de não pertencer aos grupos e vínculos.',
  'defectividade':
      'Sensação interna de inadequação, como se algo estivesse "errado" consigo.',
  'vergonha':
      'Sensação interna de inadequação, como se algo estivesse "errado" consigo.',
  'fracasso':
      'Crença de não ser capaz o suficiente diante dos outros ou das exigências.',
  'dependencia':
      'Sensação de não dar conta sozinha; busca apoio para se sentir segura.',
  'incompetencia':
      'Sensação de não dar conta sozinha; busca apoio para se sentir segura.',
  'vulnerabilidade':
      'Medo intenso de que algo ruim aconteça e de não conseguir evitá-lo.',
  'emaranhamento':
      'Vínculos muito fundidos, com dificuldade de estabelecer limites saudáveis.',
  'eu pouco':
      'Vínculos muito fundidos, com dificuldade de estabelecer limites saudáveis.',
  'subjugacao': 'Coloca-se em segundo plano para evitar conflito ou rejeição.',
  'autossacrificio':
      'Coloca as necessidades dos outros à frente das próprias, muitas vezes ao custo de si.',
  'aprovacao': 'Busca reconhecimento externo para sentir que tem valor.',
  'reconhecimento': 'Busca reconhecimento externo para sentir que tem valor.',
  'negativismo':
      'Foco no que pode dar errado; dificuldade de sustentar esperança.',
  'pessimismo':
      'Foco no que pode dar errado; dificuldade de sustentar esperança.',
  'inibicao': 'Contém emoções e impulsos espontâneos para manter controle.',
  'padroes':
      'Autocobrança elevada e dificuldade em flexibilizar regras para si e para os outros.',
  'perfeccion':
      'Autocobrança elevada e dificuldade em flexibilizar regras para si e para os outros.',
  'grandiosidade':
      'Necessidade de se sentir especial; pode reagir com competitividade quando se sente desvalorizada.',
  'arrogo':
      'Necessidade de se sentir especial; pode reagir com competitividade quando se sente desvalorizada.',
  'autocontrole': 'Dificuldade em tolerar frustração e adiar gratificações.',
};

String _normalize(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[àáâã]'), 'a')
      .replaceAll(RegExp(r'[éê]'), 'e')
      .replaceAll(RegExp(r'[íî]'), 'i')
      .replaceAll(RegExp(r'[óôõ]'), 'o')
      .replaceAll(RegExp(r'[úû]'), 'u')
      .replaceAll('ç', 'c');
}
