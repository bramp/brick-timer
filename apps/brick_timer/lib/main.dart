import 'package:brick_timer/env/env.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/catalog_service.dart';
import 'package:brick_timer/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Timer',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65D1F5),
        ),
        scaffoldBackgroundColor: const Color(0xFF93E4FC),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
