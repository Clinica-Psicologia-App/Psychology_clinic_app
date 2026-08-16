import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/homologation_ui.dart';
import '../../profile/domain/avatar_type.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_infographic_data.dart';
import '../providers/patient_infographic_providers.dart';
import 'infographic_export.dart';
import 'widgets/patient_infographic_poster.dart';

/// Tela do infográfico do paciente (lente do terapeuta): mostra o pôster
/// montado a partir dos dados reais e permite exportar em imagem e PDF.
class PatientInfographicPage extends ConsumerStatefulWidget {
  const PatientInfographicPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<PatientInfographicPage> createState() =>
      _PatientInfographicPageState();
}

class _PatientInfographicPageState
    extends ConsumerState<PatientInfographicPage> {
  final _posterKey = GlobalKey();
  final _transform = TransformationController();
  bool _busy = false;
  bool _fitApplied = false;

  static const double _posterWidth = 1000;
  static const double _posterPadding = 16;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  PatientInfographicContext get _ctx => PatientInfographicContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  Future<void> _export({required bool asPdf}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _ensureAvatarLoaded();
      final png = await InfographicExport.capturePng(_posterKey);
      final base = InfographicExport.fileBase(_patientName);
      final String path;
      if (asPdf) {
        final pdf = await InfographicExport.buildPdf(png);
        path = await InfographicExport.writeTempFile('$base.pdf', pdf);
      } else {
        path = await InfographicExport.writeTempFile('$base.png', png);
      }
      await InfographicExport.share(path, text: 'Infográfico clínico');
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _patientName = 'paciente';
  InfographicHeader? _header;

  /// Garante que a foto de rede do avatar esteja no cache antes de capturar,
  /// para o PNG/PDF não sair com o avatar ainda carregando.
  Future<void> _ensureAvatarLoaded() async {
    final h = _header;
    if (h == null ||
        h.avatarType != AvatarType.photo ||
        (h.photoUrl ?? '').trim().isEmpty) {
      return;
    }
    try {
      await precacheImage(NetworkImage(h.photoUrl!), context);
      await WidgetsBinding.instance.endOfFrame;
    } catch (_) {
      // Falha de rede degrada para iniciais — capturamos assim mesmo.
    }
  }

  /// Ajusta a escala inicial para o pôster caber na largura da tela (uma vez).
  void _applyFitToWidth(double availableWidth) {
    if (_fitApplied || availableWidth <= 0) return;
    final contentWidth = _posterWidth + _posterPadding * 2;
    final scale = (availableWidth / contentWidth).clamp(0.2, 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _transform.value = Matrix4.diagonal3Values(scale, scale, 1);
    });
    _fitApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientInfographicProvider(_ctx));

    return AppScaffold(
      title: 'Infográfico',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(patientInfographicProvider(_ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<PatientInfographicData>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientInfographicProvider(_ctx)),
        dataBuilder: (data) {
          _patientName = data.header.name;
          _header = data.header;
          if (!data.hasAnyContent) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: HomologationEmptyPanel(
                  icon: Icons.auto_graph_outlined,
                  title: 'Ainda sem material para o infográfico',
                  message:
                      'O infográfico é montado a partir dos dados já registrados '
                      'do paciente.',
                  hint: 'Preencha a Conceitualização inicial e conclua os '
                      'instrumentos para enriquecer o retrato.',
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: HomologationInfoBanner(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Material de apoio',
                  message: data.isSparse
                      ? 'Poucos dados até aqui — complete a Conceitualização '
                          'para enriquecer. Revise antes de compartilhar.'
                      : 'Gerado a partir dos dados já registrados. Revise antes '
                          'de compartilhar — é apoio à formulação, não diagnóstico.',
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _applyFitToWidth(constraints.maxWidth);
                    return InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      minScale: 0.2,
                      maxScale: 3,
                      boundaryMargin: const EdgeInsets.all(200),
                      child: Padding(
                        padding: const EdgeInsets.all(_posterPadding),
                        child: RepaintBoundary(
                          key: _posterKey,
                          child: PatientInfographicPoster(
                            data: data,
                            width: _posterWidth,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _ExportBar(
                busy: _busy,
                onImage: () => _export(asPdf: false),
                onPdf: () => _export(asPdf: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExportBar extends StatelessWidget {
  const _ExportBar({
    required this.busy,
    required this.onImage,
    required this.onPdf,
  });

  final bool busy;
  final VoidCallback onImage;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (busy) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Gerando…')),
            ] else ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Imagem'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
