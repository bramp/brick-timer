import 'package:drift/drift.dart';

/// Throws when no supported drift database implementation is available.
QueryExecutor openLedgerConnection() {
  throw UnsupportedError('No supported database implementation found.');
}
