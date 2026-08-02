import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ícones do mapa mental desenhados à mão, em mais de uma cor.
///
/// Existe porque o Material Icons é monocromático por natureza: o glifo é
/// uma fonte, então só aceita uma cor. Emoji resolveria a cor, mas o desenho
/// passa a vir do sistema do usuário — muda entre Android, iPhone e versão
/// de Android, ignora a paleta do app e traz um estilo brilhante que destoa
/// do clay plano do resto da tela.
///
/// Aqui o desenho é nosso: mesma aparência em qualquer aparelho, nas cores
/// da marca, sem dependência nova (mesma técnica já usada no avatar).
enum MentalMapArt {
  schemas,
  modes,
  problems,
  attachment,
  coping,
  parental,
  goals,
  history;

  /// Mapeia o id do nodo (vindo de patient_mental_map_page) para o desenho.
  /// Retorna null para ids sem arte própria — aí o nodo cai no ícone
  /// Material de sempre.
  static MentalMapArt? forNodeId(String id) => switch (id) {
        'schemas' => schemas,
        'modes' => modes,
        'problems' => problems,
        'attachment' => attachment,
        'coping' => coping,
        'parental' => parental,
        'goals' => goals,
        'history' => history,
        _ => null,
      };
}

class MentalMapArtIcon extends StatelessWidget {
  const MentalMapArtIcon({
    super.key,
    required this.art,
    this.size = 22,
  });

  final MentalMapArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MentalMapArtPainter(art)),
    );
  }
}

class _MentalMapArtPainter extends CustomPainter {
  const _MentalMapArtPainter(this.art);

  final MentalMapArt art;

  /// Todo desenho é feito numa grade 24x24 e depois escalado — as mesmas
  /// proporções do Material Icons, para conviver com os ícones ainda não
  /// convertidos sem parecer de outro conjunto.
  static const double _grid = 24;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _grid);
    switch (art) {
      case MentalMapArt.schemas:
        _paintBrain(canvas);
      case MentalMapArt.modes:
        _paintModes(canvas);
      case MentalMapArt.problems:
        _paintProblems(canvas);
      case MentalMapArt.attachment:
        _paintHeart(canvas);
      case MentalMapArt.coping:
        _paintShield(canvas);
      case MentalMapArt.parental:
        _paintParental(canvas);
      case MentalMapArt.goals:
        _paintGoals(canvas);
      case MentalMapArt.history:
        _paintHistory(canvas);
    }
    canvas.restore();
  }

  /// Pinta [shape] com duas cores, dividindo no eixo vertical em [split].
  /// É o truque que dá multicor sem precisar recortar dois caminhos: o
  /// contorno é um só, e o que muda é o que está por baixo do recorte.
  void _paintSplit(Canvas canvas, Path shape, Color left, Color right,
      {double split = 12}) {
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, split, _grid),
      Paint()..color = left,
    );
    canvas.drawRect(
      Rect.fromLTRB(split, 0, _grid, _grid),
      Paint()..color = right,
    );
    canvas.restore();
  }

  Paint get _lightStroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.15
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Colors.white.withValues(alpha: 0.78);

  void _paintBrain(Canvas canvas) {
    // Silhueta de cérebro: topo com três lóbulos arredondados (o gomo
    // característico), estreitando na base. Dois ovais só liam como um
    // círculo — a leitura de "cérebro" vem justamente dessa borda ondulada.
    final silhouette = Path()
      ..moveTo(12, 4)
      ..cubicTo(9.4, 3.0, 6.6, 4.4, 6.4, 6.6)
      ..cubicTo(4.2, 6.8, 3.2, 9.0, 4.6, 10.6)
      ..cubicTo(3.4, 12.0, 4.0, 14.4, 6.0, 15.0)
      ..cubicTo(6.2, 17.6, 9.0, 19.2, 12, 18.4)
      ..cubicTo(15.0, 19.2, 17.8, 17.6, 18.0, 15.0)
      ..cubicTo(20.0, 14.4, 20.6, 12.0, 19.4, 10.6)
      ..cubicTo(20.8, 9.0, 19.8, 6.8, 17.6, 6.6)
      ..cubicTo(17.4, 4.4, 14.6, 3.0, 12, 4)
      ..close();

    _paintSplit(canvas, silhouette, AppColors.blue, AppColors.purple);

    // Fissura central + um sulco de cada lado. A branca sobre o preenchido
    // dá o gomo do córtex e ainda reforça as duas cores da silhueta.
    final sulci = _lightStroke..strokeWidth = 1.25;
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.0)
        ..lineTo(12, 17.6),
      sulci,
    );
    canvas.drawPath(
      Path()
        ..moveTo(9.4, 7.2)
        ..cubicTo(7.4, 8.0, 7.6, 10.2, 9.6, 10.8)
        ..cubicTo(7.8, 11.8, 8.4, 14.2, 10.2, 14.6),
      _lightStroke..strokeWidth = 1.1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(14.6, 7.2)
        ..cubicTo(16.6, 8.0, 16.4, 10.2, 14.4, 10.8)
        ..cubicTo(16.2, 11.8, 15.6, 14.2, 13.8, 14.6),
      _lightStroke..strokeWidth = 1.1,
    );
  }

  void _paintHeart(Canvas canvas) {
    final heart = Path()
      ..moveTo(12, 20.6)
      ..cubicTo(5.2, 15.4, 3, 12.5, 3, 9.5)
      ..cubicTo(3, 6.5, 5.2, 4.5, 8, 4.5)
      ..cubicTo(9.8, 4.5, 11.2, 5.4, 12, 6.7)
      ..cubicTo(12.8, 5.4, 14.2, 4.5, 16, 4.5)
      ..cubicTo(18.8, 4.5, 21, 6.5, 21, 9.5)
      ..cubicTo(21, 12.5, 18.8, 15.4, 12, 20.6)
      ..close();

    _paintSplit(canvas, heart, AppColors.turquoise, AppColors.cyan);

    // Brilho no lobo esquerdo: dá o volume que o emoji tem, sem o acabamento
    // 3D que brigaria com o clay plano do app.
    canvas.drawPath(
      Path()
        ..moveTo(6.3, 9.2)
        ..cubicTo(6.3, 7.4, 7.4, 6.4, 8.9, 6.4),
      _lightStroke..strokeWidth = 1.5,
    );
  }

  void _paintFill(Canvas canvas, Path shape, Color color) {
    canvas.drawPath(shape, Paint()..color = color);
  }

  void _paintModes(Canvas canvas) {
    // Figura em lótus: cabeça + corpo em base larga. Modo = a persona que a
    // pessoa assume, então a figura humana lê melhor que um símbolo abstrato.
    final head = Path()
      ..addOval(
        Rect.fromCircle(center: const Offset(12, 6.2), radius: 2.5),
      );
    final body = Path()
      ..moveTo(8.6, 10.4)
      ..cubicTo(6.0, 11.2, 4.2, 13.4, 4.0, 16.4)
      ..cubicTo(3.9, 17.8, 5.2, 18.6, 7.2, 18.4)
      ..lineTo(16.8, 18.4)
      ..cubicTo(18.8, 18.6, 20.1, 17.8, 20.0, 16.4)
      ..cubicTo(19.8, 13.4, 18.0, 11.2, 15.4, 10.4)
      ..cubicTo(14.4, 12.0, 9.6, 12.0, 8.6, 10.4)
      ..close();

    final silhouette = Path.combine(PathOperation.union, head, body);
    _paintSplit(canvas, silhouette, AppColors.purple, AppColors.cyan);

    // Vinco central: separa as pernas cruzadas e reforça as duas cores.
    canvas.drawPath(
      Path()
        ..moveTo(12, 13.2)
        ..lineTo(12, 18.2),
      _lightStroke..strokeWidth = 1.2,
    );
  }

  void _paintProblems(Canvas canvas) {
    // Triângulo de alerta. É o único do conjunto propositalmente "quente":
    // problema pede atenção. Cantos levemente arredondados para não parecer
    // agressivo demais na tela do paciente.
    final triangle = Path()
      ..moveTo(12, 4.2)
      ..lineTo(20.4, 18.6)
      ..lineTo(3.6, 18.6)
      ..close();

    _paintSplit(canvas, triangle, AppColors.warning, AppColors.error);

    // Exclamação branca sólida (não stroke): a haste e o ponto.
    _paintFill(
      canvas,
      Path()
        ..addRRect(
          RRect.fromLTRBR(11.2, 9.6, 12.8, 14.2, const Radius.circular(0.8)),
        ),
      Colors.white,
    );
    _paintFill(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 16.4), radius: 1.0)),
      Colors.white,
    );
  }

  void _paintShield(Canvas canvas) {
    // Escudo: enfrentamento = proteção. Forma limpa que divide muito bem em
    // duas cores.
    final shield = Path()
      ..moveTo(12, 3.4)
      ..lineTo(19, 6.2)
      ..lineTo(19, 11.2)
      ..cubicTo(19, 15.8, 15.9, 19.2, 12, 20.8)
      ..cubicTo(8.1, 19.2, 5, 15.8, 5, 11.2)
      ..lineTo(5, 6.2)
      ..close();

    _paintSplit(canvas, shield, AppColors.cyan, AppColors.blue);

    // Tique branco: reforça a ideia de "protegido".
    canvas.drawPath(
      Path()
        ..moveTo(9.0, 12.0)
        ..lineTo(11.2, 14.2)
        ..lineTo(15.2, 9.4),
      _lightStroke..strokeWidth = 1.7,
    );
  }

  void _paintParental(Canvas canvas) {
    // Adulto (maior, à esquerda) + criança (menor, à direita). As duas cores
    // são as duas pessoas — literal, não decorativo. O split cai entre elas.
    final adult = Path()
      ..addOval(Rect.fromCircle(center: const Offset(8.2, 6.0), radius: 2.4))
      ..moveTo(4.8, 19.2)
      ..lineTo(4.8, 13.0)
      ..cubicTo(4.8, 10.6, 11.6, 10.6, 11.6, 13.0)
      ..lineTo(11.6, 19.2)
      ..close();
    final child = Path()
      ..addOval(Rect.fromCircle(center: const Offset(16.4, 9.2), radius: 1.9))
      ..moveTo(13.6, 19.2)
      ..lineTo(13.6, 14.6)
      ..cubicTo(13.6, 12.7, 19.2, 12.7, 19.2, 14.6)
      ..lineTo(19.2, 19.2)
      ..close();

    _paintSplit(canvas, adult, AppColors.purple, AppColors.purple);
    _paintSplit(canvas, child, AppColors.cyan, AppColors.cyan);
  }

  void _paintGoals(Canvas canvas) {
    // Alvo: três anéis concêntricos. Substitui a bandeira (que era o único
    // glifo Material realmente torto) e lê como "objetivo" na hora.
    canvas.drawCircle(
      const Offset(12, 12),
      8.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = AppColors.turquoise,
    );
    canvas.drawCircle(
      const Offset(12, 12),
      4.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.turquoise.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      const Offset(12, 12),
      2.1,
      Paint()..color = AppColors.success,
    );
  }

  void _paintHistory(Canvas canvas) {
    // Relógio: história = a linha do tempo do caso. Mostrador bicolor,
    // ponteiros brancos.
    final face = Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 12.4), radius: 8.2));
    _paintSplit(canvas, face, AppColors.cyan, AppColors.blue, split: 12);

    final hands = _lightStroke..strokeWidth = 1.5;
    canvas.drawPath(
      Path()
        ..moveTo(12, 12.4)
        ..lineTo(12, 7.8),
      hands,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 12.4)
        ..lineTo(15.6, 13.8),
      hands,
    );
    _paintFill(
      canvas,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12.4), radius: 1.1)),
      Colors.white,
    );
  }

  @override
  bool shouldRepaint(_MentalMapArtPainter oldDelegate) =>
      oldDelegate.art != art;
}
