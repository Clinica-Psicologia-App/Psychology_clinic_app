import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/questionnaire_catalog_admin_repository.dart';
import '../domain/questionnaire_catalog_admin.dart';

final questionnaireCatalogAdminRepositoryProvider =
    Provider<QuestionnaireCatalogAdminRepository>(
        (_) => QuestionnaireCatalogAdminRepository());

final questionnaireCatalogAdminListProvider =
    FutureProvider<List<QuestionnaireCatalogAdminItem>>((ref) {
  return ref.read(questionnaireCatalogAdminRepositoryProvider).list();
});

final questionnaireCatalogAdminDetailProvider =
    FutureProvider.family<QuestionnaireCatalogDetail, String>((ref, id) {
  return ref.read(questionnaireCatalogAdminRepositoryProvider).get(id);
});
