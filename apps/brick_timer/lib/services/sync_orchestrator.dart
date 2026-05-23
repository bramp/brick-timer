import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/spreadsheet_service.dart';

/// Orchestrates synchronization between the local ledger and the spreadsheet.
class SyncOrchestrator {
  /// Creates a new [SyncOrchestrator].
  SyncOrchestrator({
    required this.ledger,
    required this.api,
  });

  /// The local ledger repository.
  final LedgerRepository ledger;

  /// The spreadsheet service for remote sync.
  final SpreadsheetService api;

  /// Attempts to sync all pending completed bags.
  Future<void> syncPendingBags() async {
    final pending = await ledger.getUnsyncedBags();

    for (final bag in pending) {
      final session = await ledger.getSession(bag.buildSessionId);
      if (session != null) {
        final legoSet = await ledger.getLegoSet(session.legoSetId);
        if (legoSet != null) {
          final totalMins = await ledger.getTotalDurationMinutes(
            session.id,
            bag.bagNumber,
          );
          final success = await api.syncCompletedBag(
            setNumber: legoSet.setNumber,
            setName: legoSet.name,
            bagNumber: bag.bagNumber,
            totalDurationMinutes: totalMins,
          );
          if (success) {
            await ledger.updateBagSyncStatus(bag.id, synced: true);
          }
        }
      }
    }
  }
}
