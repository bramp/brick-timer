# Brick Timer Implementation Plan (TODO)

## Phase 1: Local Ledger Foundation 🏃 (Current)
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
- [ ] Add `firebase_crashlytics` for production crash/error reporting.
- [ ] Add `firebase_analytics` for usage/event telemetry.
- [x] Implement `SpreadsheetService` to POST completed bag payloads (JSON: date, setNumber, setName, bagNumber, totalDurationMinutes) to the Google Apps Script Webhook.
- [x] Wire the automated background sync trigger when a bag status moves to complete.

## Phase 4: Interface & Polish
- [x] Construct Dashboard UI (In-Progress builds, historic stats, Cloud Sync Status Widget, FAB to start new build).
- [ ] Construct Rebrickable Search Portal (Search text field with 500ms debounce, dynamic list with thumbnails).
- [ ] Revisit LEGO catalog search pagination so the backend can return an opaque "more pages" token and the UI can load more results as needed, instead of relying on a single filtered page.
- [ ] Construct Active Build Workspace (Prominent image, giant running stopwatch, Start/Pause/Resume/Complete buttons).
- [ ] Add manual adjustments ("Oops, forgot to start" offset controls).
- [ ] Add simple line/bar visual charts for tracking bricks-per-minute trends.
- [ ] Wire the GitHub Pages build metadata (`COMMIT_HASH` and `BUILD_DATE`) into the app UI, using a small `BuildInfo` helper backed by `String.fromEnvironment`, similar to https://github.com/bramp/grids `apps/grids/lib/build_info.dart`.
- [ ] Pull down to refresh
- [ ] Make all text copied and pastable.