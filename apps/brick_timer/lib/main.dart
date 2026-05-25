import 'package:brick_timer/env/env.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/catalog_service.dart';
import 'package:brick_timer/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// The global ledger repository instance.
final ledgerRepository = LedgerRepository();

/// Starts the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(bramp): Let's add a splash screen

  await ledgerRepository.init();

  final catalogService = CatalogService.create(
    rebrickableApiKey: Env.rebrickableApiKey,
  );
  await catalogService.warmUp();

  runApp(const ProviderScope(child: BrickTimerApp()));
}

/// The root widget of the application.
class BrickTimerApp extends StatelessWidget {
  /// Creates a new [BrickTimerApp] instance.
  const BrickTimerApp({super.key});

  static const Color _backgroundColor = Color(0xFF93E4FC);
  static const Color _surfaceColor = Color(0xFFEAF8FF);
  static const Color _primaryColor = Color(0xFF65D1F5);
  static const Color _coralAccent = Color(0xFFEF3E2D);
  static const Color _yellowAccent = Color(0xFFFDD904);
  static const Color _onColor = Color(0xFF0B2430);

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: _primaryColor,
      onPrimary: _onColor,
      secondary: _coralAccent,
      onSecondary: Colors.white,
      tertiary: _yellowAccent,
      onTertiary: _onColor,
      surface: _surfaceColor,
      onSurface: _onColor,
      outlineVariant: Color(0xFF9ED8E8),
      error: _coralAccent,
    );
    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: GoogleFonts.nunito(
        textStyle: baseTextTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.nunito(
        textStyle: baseTextTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.nunito(
        textStyle: baseTextTheme.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
    );

    return MaterialApp(
      title: 'Brick Timer',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: colorScheme,
        textTheme: textTheme,
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _backgroundColor,
          foregroundColor: _onColor,
          // TODO(bramp): Replace the AppBar title text with an SVG logo.
          // Then remove the google_fonts dependency and Nunito overrides.
          titleTextStyle: GoogleFonts.nunito(
            textStyle: baseTextTheme.titleLarge?.copyWith(
              color: _onColor,
              fontSize: 26,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: const CardThemeData(
          color: _surfaceColor,
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
