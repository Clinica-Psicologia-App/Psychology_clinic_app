import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_banner.dart';
import '../domain/library_indication.dart';
import '../domain/library_work.dart';
import '../providers/patient_library_providers.dart';
import 'widgets/library_cover.dart';

/// Experiência do paciente numa obra indicada: antes / durante / depois de
/// assistir, com ativação 0–10 e cuidados de segurança. Tema escuro.
class PatientLibraryWorkPage extends ConsumerStatefulWidget {
  const PatientLibraryWorkPage({super.key, required this.indicationId});

  final String indicationId;

  @override
  ConsumerState<PatientLibraryWorkPage> createState() =>
      _PatientLibraryWorkPageState();
}

class _PatientLibraryWorkPageState
    extends ConsumerState<PatientLibraryWorkPage> {
  static const _bg = Color(0xFF0B0B10);
  static const _accent = Color(0xFF00C2B8);

  final _answers = <int, TextEditingController>{};
  double _activation = 0;
  bool _share = false;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(LibraryIndication ind) {
    if (_prefilled) return;
    _activation = (ind.activation ?? 0).toDouble();
    _share = ind.shareResponses;
    final saved = ind.patientResponses ?? const {};
    final questions = ind.work.patientLayer.after;
    for (var i = 0; i < questions.length; i++) {
      if (_isActivation(questions[i])) continue;
      _answers[i] =
          TextEditingController(text: (saved['q$i'] ?? '').toString());
    }
    _prefilled = true;
  }

  bool _isActivation(LibraryQuestion q) =>
      (q.fieldType ?? '').toLowerCase().contains('escala') ||
      (q.fieldType ?? '').contains('0 a 10');

  Future<void> _markStarted(LibraryIndication ind) async {
    await _update(ind, status: 'Em andamento');
  }

  Future<void> _submit(LibraryIndication ind) async {
    final responses = <String, dynamic>{};
    _answers.forEach((i, c) {
      if (c.text.trim().isNotEmpty) responses['q$i'] = c.text.trim();
    });
    await _update(
      ind,
      status: 'Assistido',
      watchedAt: DateTime.now(),
      activation: _activation.round(),
      responses: responses,
    );
  }

  Future<void> _update(
    LibraryIndication ind, {
    String? status,
    DateTime? watchedAt,
    int? activation,
    Map<String, dynamic>? responses,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(patientLibraryRepositoryProvider).updateMyIndication(
            indicationId: ind.id,
            status: status,
            watchedAt: watchedAt,
            activation: activation,
            shareResponses: _share,
            patientResponses: responses,
          );
      ref.invalidate(myLibraryIndicationsProvider);
      ref.invalidate(myLibraryContentProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == 'Assistido'
                ? 'Respostas enviadas. Obrigado por compartilhar.'
                : 'Tudo certo — bom filme!')),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myLibraryIndicationsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white54)),
        error: (e, _) => _msg('Não foi possível carregar a obra'),
        data: (list) {
          LibraryIndication? ind;
          for (final i in list) {
            if (i.id == widget.indicationId) ind = i;
          }
          if (ind == null) return _msg('Obra não encontrada');
          _prefill(ind);
          return _body(ind);
        },
      ),
    );
  }

  Widget _body(LibraryIndication ind) {
    final w = ind.work;
    final layer = w.patientLayer;
    final highActivation = _activation >= 8;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            _cover(w),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Antes de assistir
                  _Section(
                    title: 'Antes de assistir',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((layer.before ?? '').isNotEmpty)
                          Text(layer.before!,
                              style: const TextStyle(
                                  color: Colors.white70, height: 1.5)),
                        if (w.intensity != null) ...[
                          const SizedBox(height: 12),
                          _ContentAlert(intensity: w.intensity!),
                        ],
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : () => _markStarted(ind),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Vou assistir'),
                        ),
                      ],
                    ),
                  ),
                  // Durante
                  if (layer.during.isNotEmpty)
                    _Section(
                      title: 'Enquanto assiste, observe',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final d in layer.during)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined,
                                      size: 16, color: _accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(d,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Depois de assistir
                  if (layer.after.isNotEmpty)
                    _Section(
                      title: 'Depois de assistir',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < layer.after.length; i++)
                            if (!_isActivation(layer.after[i]))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _QuestionField(
                                  question: layer.after[i].question,
                                  controller: _answers[i]!,
                                ),
                              ),
                          const SizedBox(height: 4),
                          _ActivationSlider(
                            value: _activation,
                            onChanged: (v) => setState(() => _activation = v),
                          ),
                          if (highActivation) ...[
                            const SizedBox(height: 12),
                            const _SafetyCard(),
                          ],
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _share,
                            onChanged: (v) => setState(() => _share = v),
                            activeThumbColor: _accent,
                            title: const Text(
                              'Compartilhar minhas respostas com meu psicólogo',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: _saving ? null : () => _submit(ind),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.check),
                            label: Text(
                                _saving ? 'Enviando…' : 'Enviar respostas'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cover(LibraryWork w) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LibraryCover(
            gradient: _gradientFor(w.id),
            url: w.coverUrl,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1.0],
                colors: [Colors.transparent, _bg],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(w.displayTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  [
                    w.workType,
                    if (w.year != null) '${w.year}',
                    if (w.intensity != null) 'Intensidade ${w.intensity}',
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _msg(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ),
      );

  List<Color> _gradientFor(String id) {
    const palette = <List<Color>>[
      [Color(0xFF3B2F8F), Color(0xFF11808F)],
      [Color(0xFF7A2E5D), Color(0xFF2B1030)],
      [Color(0xFF1F6FEB), Color(0xFF0B2A5B)],
      [Color(0xFFB5462A), Color(0xFF3A150C)],
      [Color(0xFF2E7D57), Color(0xFF0F2E22)],
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ContentAlert extends StatelessWidget {
  const _ContentAlert({required this.intensity});
  final String intensity;

  @override
  Widget build(BuildContext context) {
    final high = intensity.toLowerCase() == 'alta';
    final color = high ? const Color(0xFFE8A33D) : Colors.white54;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              high
                  ? 'Esta obra tem intensidade alta e pode trazer cenas fortes. '
                      'Assista com cuidado e pause se precisar.'
                  : 'Intensidade $intensity. Assista no seu ritmo e pause se '
                      'perceber ativação emocional.',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({required this.question, required this.controller});
  final String question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Sua resposta…',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivationSlider extends StatelessWidget {
  const _ActivationSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Qual foi a intensidade da ativação emocional?',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            Text('${value.round()}',
                style: const TextStyle(
                    color: Color(0xFF00C2B8),
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: const Color(0xFF00C2B8),
          label: '${value.round()}',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0519A).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFE0519A).withValues(alpha: 0.45)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 18, color: Color(0xFFE0519A)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Percebi que mexeu bastante com você',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Tudo bem sentir. Respire com calma, faça uma pausa se precisar e '
            'lembre do recurso de regulação que você combinou com seu psicólogo. '
            'Se quiser, avise seu psicólogo.',
            style:
                TextStyle(color: Colors.white70, height: 1.4, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
