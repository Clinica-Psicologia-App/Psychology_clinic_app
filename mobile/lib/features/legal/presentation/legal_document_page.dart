import 'package:flutter/material.dart';

import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/responsive_content.dart';

enum LegalDocumentType { terms, privacy }

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.type,
  });

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final isTerms = type == LegalDocumentType.terms;
    final title =
        isTerms ? LegalDocuments.termsTitle : LegalDocuments.privacyTitle;
    final version =
        isTerms ? LegalDocuments.termsVersion : LegalDocuments.privacyVersion;
    final text =
        isTerms ? LegalDocuments.termsText : LegalDocuments.privacyText;

    return AppScaffold(
      title: title,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ResponsiveContent(
            maxWidth: 760,
            child: MotionReveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: title,
                    subtitle:
                        'Documento legal vigente para uso da plataforma EsquemaCore.',
                    icon: isTerms
                        ? Icons.description_outlined
                        : Icons.privacy_tip_outlined,
                    metadata: [
                      Chip(label: Text('Versão $version')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppInfoCard(
                    title: 'Conteúdo',
                    icon: Icons.article_outlined,
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
