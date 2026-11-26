import 'package:go_router/go_router.dart';

import 'admin_library_catalog_page.dart';
import 'admin_library_editor_page.dart';

/// Rotas de curadoria do catálogo da Biblioteca (somente admin, sob /platform).
abstract final class AdminLibraryRoutes {
  static const catalog = '/platform/library';
  static const newWork = '/platform/library/new';
  static String work(String id) => '/platform/library/$id';
}

List<RouteBase> adminLibraryRoutes() {
  return [
    GoRoute(
      path: 'library',
      name: AdminLibraryRoutes.catalog,
      builder: (_, __) => const AdminLibraryCatalogPage(),
      routes: [
        GoRoute(
          path: 'new',
          name: AdminLibraryRoutes.newWork,
          builder: (_, __) => const AdminLibraryEditorPage(),
        ),
        GoRoute(
          path: ':workId',
          name: '/platform/library/:workId',
          builder: (_, state) => AdminLibraryEditorPage(
            workId: state.pathParameters['workId'],
          ),
        ),
      ],
    ),
  ];
}
