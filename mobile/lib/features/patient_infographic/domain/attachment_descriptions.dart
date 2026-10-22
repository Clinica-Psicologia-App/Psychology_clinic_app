/// Descrições curtas dos estilos de apego (questionário ATTACHMENT_STYLES_V1),
/// para o infográfico — no mesmo formato do catálogo de esquemas.
///
/// Não é diagnóstico: é psicoeducação de apoio, sempre sob revisão do
/// profissional. Textos a validar com a equipe clínica.
String? attachmentDescriptionFor(String style) {
  final key = _normalize(style);
  for (final entry in _byKeyword.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Título do bloco: "Apego seguro", "Apego ansioso"… (sem repetir "apego").
String attachmentTitleFor(String style) {
  final t = style.trim();
  if (t.isEmpty) return t;
  if (_normalize(t).contains('apego')) return t;
  return 'Apego ${t[0].toLowerCase()}${t.substring(1)}';
}

const Map<String, String> _byKeyword = {
  'seguro':
      'Sente-se à vontade com proximidade e com autonomia; confia que pode contar com os outros e busca apoio quando precisa.',
  'ansioso':
      'Deseja muita proximidade e teme rejeição ou abandono; tende a buscar confirmação constante do vínculo.',
  'evitante':
      'Valoriza independência e distância emocional; tende a se proteger evitando depender dos outros ou mostrar vulnerabilidade.',
  'desorganizado':
      'Oscila entre buscar e evitar proximidade; os vínculos podem ser vividos como desejados e ameaçadores ao mesmo tempo.',
};

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éê]'), 'e')
    .replaceAll(RegExp('[í]'), 'i')
    .replaceAll(RegExp('[óôõ]'), 'o')
    .replaceAll(RegExp('[ú]'), 'u')
    .replaceAll('ç', 'c');
