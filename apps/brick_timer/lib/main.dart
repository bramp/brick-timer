import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The global ledger repository instance.
final ledgerRepository = LedgerRepository();

/// Starts the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODOlet's add a splash screen

  await ledgerRepository.init();

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
