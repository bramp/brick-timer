import 'package:brick_timer/repositories/db_connection_stub.dart'
    if (dart.library.js_interop) 'db_connection_web.dart'
    if (dart.library.io) 'db_connection_native.dart'
    as impl;
import 'package:drift/drift.dart';

/// Opens a platform-specific drift connection implementation.
QueryExecutor openLedgerConnection() => impl.openLedgerConnection();
