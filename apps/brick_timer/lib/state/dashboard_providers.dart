import 'package:brick_timer/main.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for watching all build sessions.
final buildSessionsProvider = StreamProvider<List<BuildSessionWithSet>>((ref) {
  return ledgerRepository.watchBuildSessions();
});

/// Provider for watching the count of unsynced completed bags.
final unsyncedBagsCountProvider = StreamProvider<int>((ref) {
  return ledgerRepository.watchUnsyncedBagsCount();
});
