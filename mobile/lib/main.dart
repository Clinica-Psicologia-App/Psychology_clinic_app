import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/theme/app_typography.dart';

Future<void> _preloadFonts() {
  return GoogleFonts.pendingFonts([
    GoogleFonts.poppins(fontWeight: FontWeight.w400),
    GoogleFonts.poppins(fontWeight: FontWeight.w500),
    GoogleFonts.poppins(fontWeight: FontWeight.w600),
    GoogleFonts.poppins(fontWeight: FontWeight.w700),
  ]).then((_) {
    AppTypography.textTheme();
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    _preloadFonts(),
    SupabaseBootstrap.initialize(),
  ]);

  runApp(
    const ProviderScope(
      child: TerapiaEsquemaApp(),
    ),
  );
}
