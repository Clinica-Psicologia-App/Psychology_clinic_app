import 'package:flutter/material.dart';

/// Correção de centramento óptico para glifos do Material Icons cuja "tinta"
/// não fica centrada dentro da própria caixa (em-square). O Flutter centraliza
/// a caixa corretamente, então qualquer desvio percebido vem só do desenho da
/// fonte — um triângulo é pesado na base, uma bandeira pende para o mastro etc.
///
/// Os valores abaixo são o **desvio medido** do centroide da tinta (canal alfa)
/// em relação ao centro da caixa, como fração do tamanho do ícone. São gerados
/// por `test/tools/measure_icon_drift.dart` — rode-o de novo se precisar de
/// outro glifo. A correção aplicada é o negativo do desvio.
///
/// Só entram aqui glifos com desvio perceptível (≥ ~3% do tamanho num eixo);
/// os demais são desenhados suficientemente centrados e retornam [Offset.zero].
Offset _driftFor(IconData icon) {
  if (icon == Icons.report_problem_outlined) return const Offset(-0.0020, 0.1053);
  if (icon == Icons.self_improvement_outlined) return const Offset(-0.0009, 0.0924);
  if (icon == Icons.favorite_border) return const Offset(-0.0022, -0.0667);
  if (icon == Icons.schema_outlined) return const Offset(-0.0865, -0.0020);
  if (icon == Icons.flag_outlined) return const Offset(-0.0132, -0.0480);
  return Offset.zero;
}

/// Limiar abaixo do qual o eixo é considerado já centrado (evita micro-ajustes
/// que só adicionam ruído).
const double _kNudgeThreshold = 0.03;

/// Retorna o deslocamento a aplicar num [Transform.translate] para trazer a
/// tinta de [icon] ao centro da caixa, no tamanho [size]. É o negativo do
/// desvio medido, zerando eixos abaixo do limiar perceptível.
Offset opticalIconNudge(IconData icon, double size) {
  final drift = _driftFor(icon);
  final dx = drift.dx.abs() >= _kNudgeThreshold ? -drift.dx * size : 0.0;
  final dy = drift.dy.abs() >= _kNudgeThreshold ? -drift.dy * size : 0.0;
  return Offset(dx, dy);
}

/// Envolve um [Icon] no nudge óptico de [icon]. Conveniência para os pontos que
/// desenham um ícone centralizado num círculo/hub e precisam do ajuste fino.
class OpticallyCenteredIcon extends StatelessWidget {
  const OpticallyCenteredIcon({
    super.key,
    required this.icon,
    required this.size,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: opticalIconNudge(icon, size),
      child: Icon(icon, size: size, color: color),
    );
  }
}
