import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';

/// Vídeo de introdução do app, tocado uma única vez como abertura do
/// onboarding (spec de UX: transição de entrada). Mudo e em autoplay (para
/// funcionar também na web), em tela cheia, com "Pular". Ao terminar — ou se
/// falhar ao carregar — segue para os slides via [onDone].
class IntroVideoView extends StatefulWidget {
  const IntroVideoView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroVideoView> createState() => _IntroVideoViewState();
}

class _IntroVideoViewState extends State<IntroVideoView> {
  VideoPlayerController? _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller =
        VideoPlayerController.asset('assets/intro/app_intro.mp4');
    _controller = controller;
    controller.addListener(_onTick);
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setVolume(0);
      await controller.setLooping(false);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      _finish(); // sem vídeo, vai direto aos slides
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.hasError) {
      _finish();
      return;
    }
    final dur = c.value.duration;
    final pos = c.value.position;
    final ended = dur > Duration.zero &&
        pos >= dur - const Duration(milliseconds: 150) &&
        !c.value.isPlaying;
    if (ended) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.splashBackground),
          ),
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          if (!ready)
            const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white70),
              ),
            ),
          // Botão "Pular" com leve escurecimento para legibilidade.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    ),
                    child: const Text('Pular'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
