import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

const _databaseName = 'brick_timer_db';

/// Opens the web drift database backed by the wasm SQLite implementation.
QueryExecutor openLedgerConnection() {
  return DatabaseConnection.delayed(
    Future<DatabaseConnection>(() async {
      final result = await WasmDatabase.open(
        databaseName: _databaseName,
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      developer.log(
        'Drift web backend selected: ${result.chosenImplementation}',
        name: 'brick_timer.db',
      );
      // TODO(bramp): Emit this backend selection as a Firebase Analytics
      // event once Firebase is initialized.

      if (result.missingFeatures.isNotEmpty) {
        developer.log(
          'Drift web using ${result.chosenImplementation} '
          'due to missing features: ${result.missingFeatures}',
          name: 'brick_timer.db',
        );
      }

      return DatabaseConnection(result.resolvedExecutor);
    }),
  );
}
