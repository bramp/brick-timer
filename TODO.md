# Brick Timer Implementation Plan (TODO)

## Phase 1: Local Ledger Foundation
- [x] Add `drift`, `sqlite3_flutter_libs`, and `path_provider` dependencies.
- [x] Initialize the Drift database engine in `main.dart`.
- [x] Scaffold the high-level Drift models:
  - [x] `LegoSet` (Set Number, Name, Total Pieces, Image URL)
  - [x] `BuildSession` (Tracks overall start date and absolute completion status)
  - [x] `BagInterval` (Tracks `startTime` and `endTime` for a specific bag)
  - [x] `CompletedBag` (Unified record of a completed bag, tracks `isSynced` flag)
- [x] Write local repository operations (`LedgerRepository`):
  - [x] Fetch active durations
  - [x] Query un-synced dependencies
  - [x] Save/update models

## Phase 2: Reactive Timing Engine
- [x] Add `flutter_riverpod` dependency.
- [x] Construct the Riverpod `ActiveSessionNotifier` to manage state changes (Stopped, Running, Paused).
- [x] Incorporate crash resiliency logic: On app initialization, check for open-ended intervals (null `endTime`) and automatically resolve them relative to the current time.

## Phase 3: Networking & Integrations
- [x] Add `http` dependency.
- [x] Implement abstract `LegoCatalogService` interface to future-proof API calls.
- [x] Implement `RebrickableService` to query Rebrickable's API v3 endpoint for set data (currently using test key).
- [ ] Add alternative `packages/lego_catalog` backend to use a Firebase Serverless Proxy to secure the API key via App Check/Auth.
- [x] Add `firebase_crashlytics` for production crash/error reporting (wired in `FirebaseBootstrap`, enabled via `--dart-define=FIREBASE_ENABLED=true`).
- [x] Add `firebase_analytics` for usage/event telemetry (wired in `FirebaseBootstrap`, enabled via `--dart-define=FIREBASE_ENABLED=true`).
- [x] Implement `SpreadsheetService` to POST completed bag payloads (JSON: date, setNumber, setName, bagNumber, totalDurationMinutes) to the Google Apps Script Webhook.
- [x] Wire the automated background sync trigger when a bag status moves to complete.

## Phase 4: Interface & Polish 🏃 (Current)
- [x] Construct Dashboard UI (In-Progress builds, historic stats, Cloud Sync Status Widget, FAB to start new build).
- [x] Construct Rebrickable Search Portal (search text field with 500ms debounce, dynamic list with thumbnails, pull-to-refresh, and error recovery with friendly messages).
- [x] Construct Active Build Workspace (set image, running stopwatch, Start Bag / Bag Finished / Pause / Resume / Finished Set controls, embedded in the dashboard active build card).
- [ ] Revisit LEGO catalog search pagination: add an opaque `nextPageToken` to the `LegoCatalogBackend.searchSets` interface and a "Load more" button in the search UI, instead of relying on a single filtered page.
- [ ] Add manual adjustments ("Oops, forgot to start" offset controls).
- [ ] Add simple line/bar visual charts for tracking bricks-per-minute trends.
- [ ] Wire the GitHub Pages build metadata (`COMMIT_HASH` and `BUILD_DATE`) into the app UI, using a small `BuildInfo` helper backed by `String.fromEnvironment`, similar to https://github.com/bramp/grids `apps/grids/lib/build_info.dart`.
- [ ] Pull down to refresh on the Dashboard (the search screen already has it).
- [ ] Make all text copyable (beyond the error details section in search).
- [ ] Fix SVG asset compatibility warnings by cleaning unsupported editor metadata (e.g. `sodipodi:namedview`, `inkscape:path-effect`) from app SVG files, and add a lightweight validation step so bad SVGs do not regress.
- [ ] Fix Flutter web viewport warning by removing the custom `<meta name="viewport">` from `web/index.html` and relying on Flutter's managed viewport configuration.

## Phase 5: Stability & Test Coverage
- [ ] Add unit tests for `SyncOrchestrator`: success path marks bag as synced, network failure leaves bag pending, partial batch failure does not corrupt remaining records, and repeated calls are idempotent.
- [ ] Add unit tests for `SpreadsheetService`: verify correct JSON payload shape, non-200 response returns `false`, exception returns `false`.
- [ ] Add an integration test for crash recovery: simulate an app restart with an open-ended `BagInterval` (null `endTime`) and verify `ActiveSessionNotifier` correctly closes it on hydration.
- [ ] Harden `SyncOrchestrator` with exponential back-off retry for transient network failures, so a single bad network moment does not permanently strand unsynced records.
- [ ] Harden the sync status widget: surface the last-error state and show a visible "retry" affordance when sync fails, rather than only showing an unsynced count.