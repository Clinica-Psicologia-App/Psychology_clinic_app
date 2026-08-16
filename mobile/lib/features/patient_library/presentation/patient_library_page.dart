import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/library_content.dart';
import '../providers/patient_library_providers.dart';
import 'patient_library_routes.dart';
import 'widgets/patient_library_view.dart';

/// Biblioteca do paciente (estilo streaming). Tema escuro fixo e imersivo.
class PatientLibraryPage extends ConsumerWidget {
  const PatientLibraryPage({super.key});

  static const _bg = Color(0xFF0B0B10);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myLibraryContentProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => _DarkMessage(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar a Biblioteca',
              onRetry: () => ref.invalidate(myLibraryContentProvider),
            ),
            data: (content) => content == null
                ? const _DarkMessage(
                    icon: Icons.movie_filter_outlined,
                    title: 'Sua Biblioteca está a caminho',
                    message: 'Seu psicólogo ainda não indicou obras para você. '
                        'Quando indicar, elas aparecem aqui.',
                  )
                : _Content(content: content),
          ),
          // Botão de voltar flutuante sobre o hero.
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
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.content});
  final LibraryContent content;

  @override
  Widget build(BuildContext context) {
    return PatientLibraryView(
      content: content,
      onItemTap: (item) =>
          context.push(PatientLibraryRoutes.patientWork(item.id)),
      onHeroTap: content.hero.id == null
          ? null
          : () => context.push(
                PatientLibraryRoutes.patientWork(content.hero.id!),
              ),
    );
  }
}

class _DarkMessage extends StatelessWidget {
  const _DarkMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, height: 1.4),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
