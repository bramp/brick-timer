import 'package:brick_time/repositories/ledger_repository.dart';
import 'package:brick_time/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The global ledger repository instance.
final ledgerRepository = LedgerRepository();

/// Starts the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODOlet's add a splash screen

  await ledgerRepository.init();

  runApp(const ProviderScope(child: BrickTimeApp()));
}

/// The root widget of the application.
class BrickTimeApp extends StatelessWidget {
  /// Creates a new [BrickTimeApp] instance.
  const BrickTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrickTime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
