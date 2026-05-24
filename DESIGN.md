# System Design Document: Brick Timer (LEGO Build Tracker)

This document serves as the comprehensive architectural blueprint and implementation plan for **Brick Timer**, a local-first, low-friction Flutter application designed to replace manual spreadsheet tracking for LEGO set assembly.

---

## 1. Executive Summary & Core Objectives

The purpose of Brick Timer is to track the exact time it takes to build a LEGO set on a per-bag basis with **zero operational friction**. The app targets a "handfree/dusty-hands" UX, prioritizing giant tap targets, resilient local persistence, and intelligent data aggregation.

### Key Workflows

* **Discovery:** Search sets via the Rebrickable API by ID or name to auto-populate metadata (images, total pieces) without manual entry.
* **Time Tracking:** A simple Start/Pause/Complete lifecycle per bag. The app must handle multi-day interruptions on a single bag cleanly.
* **Hybrid Synchronization:** Automatically pushes data to an external spreadsheet over the network upon bag completion, dropping back to a cached local state with a manual "Sync Now" fallback if offline.

---

## 2. Technical Stack

* **Frontend Framework:** Flutter (Cross-platform)
* **State Management:** Riverpod (Reactive, async-driven architecture)
* **Local Database:** Drift Database (High-performance SQLite local storage for Flutter)
* **External Integration:** Rebrickable API v3 (REST) via a future Firebase Serverless Proxy to securely protect API keys using App Check/Authentication.
* **Spreadsheet Target:** Google Sheets via a lightweight Google Apps Script Webhook (HTTP POST payload)

---

## 3. System Architecture & Data Strategy

### Local Storage Architecture (Drift-focused)

To avoid intricate real-time calculations or complex duration arrays, the app relies on an **Interval Ledger System**.

* **`LegoSet`**: Caches the core structural data fetched from Rebrickable (Set Number, Name, Total Pieces, Image URL).
* **`BuildSession`**: Represents a single setup of a set (Tracks overall start date and absolute completion status).
* **`BagInterval`**: Captures raw timestamps. Every time you press "Start" or "Resume", a row is written with a `startTime`. Pressing "Pause" writes the `endTime`. If the app crashes or is killed by the OS, an active interval is recovered by identifying a null `endTime`.
* **`CompletedBag`**: When a user marks a bag as done, the app sums all related `BagInterval` durations, creates a unified `CompletedBag` record, and marks it as `isSynced = false`.

### The State Machine

The core stopwatch UI acts as a finite state machine driven by Riverpod:

* **Stopped Status:** Displaying "Start Bag X".
* **Running Status:** Timer ticking upward; displaying "Pause" and "Complete Bag".
* **Paused Status:** Timer frozen; displaying "Resume" and "Complete Bag".

---

## 4. Synchronization Strategy

The application decouples local data saving from external network operations to maximize performance and offline usability.

```text
 [Tap: Complete Bag] 
          │
          ▼
 ┌────────────────────────────────┐
 │ Save CompletedBag Local Record │ ──► (isSynced = false)
 └────────────────────────────────┘
          │
          ├─────────────────────────────────────────┐
          ▼ (Async Background Trigger)              ▼ (Network Fails / Offline)
 ┌────────────────────────────────┐        ┌────────────────────────────────┐
 │ HTTP POST to Apps Script URL   │        │ Keep Local Record as Unsynced  │
 └────────────────────────────────┘        └────────────────────────────────┘
          │                                         │
          ▼ (On 200 OK Success)                     ▼ (User returns online)
 ┌────────────────────────────────┐        ┌────────────────────────────────┐
 │   Update isSynced = true       │        │ Tap Manual "Sync" Dashboard Button│
 └────────────────────────────────┘        └────────────────────────────────┘

```

### Google Apps Script Endpoint

The backend sheet relies on a micro-service script to process incoming payloads without requiring full Google OAuth workflows inside Flutter:

* Receives a clean JSON package containing: `date`, `setNumber`, `setName`, `bagNumber`, and `totalDurationMinutes`.
* Appends the fields as a clean row to the target sheet.

---

## 5. UI/UX Design Specifications

### Screen 1: The Dashboard

* A minimalistic entry portal showing current "In-Progress" builds, historic stats, and a dominant **Floating Action Button (+)** to start a new build.
* A **Cloud Sync Status Widget** indicating if there are pending local items. If items are out of sync, it turns into an interactive button showing: `[ X Bags Pending Sync - Tap to Retry ]`.

### Screen 2: The Rebrickable Search Portal

* A search text field with an aggressive 500ms debounce to prevent API thrashing.
* A dynamic list displaying query match options containing thumbnail art, formal set titles, and total brick counts. Clicking an element instantiates the local DB session.
* Future iteration: switch this screen to a paged/infinite-scroll model so locally filtered pages can continue loading when the backend still has more results.

### Screen 3: The Active Build Workspace

* A minimal layout designed to be read from a distance. Includes a prominent image of the set and a giant running stopwatch.
* Primary Controls: Large, easy-to-hit action buttons changing status contextually based on the state machine (Start, Pause, Resume, Complete).

### Material Design Requirements

* Follow Material Design 3 best practices across all Flutter UI screens and components.
* Prefer built-in Material widgets (for example: `Scaffold`, `AppBar`, `Card`, `ListTile`, `FilledButton`, `SnackBar`) before custom alternatives.
* Use Material color roles, typography, shape, spacing, and elevation consistently to keep the app accessible and visually coherent.
* Use clear empty/loading/error states with actionable recovery patterns (for example: pull-to-refresh and retry buttons) instead of raw exception text.

### Testing Requirements

* Every behavior change must include automated tests in the same pull request.
* Add or update unit tests for business logic and provider/repository behavior.
* Add or update widget tests for UI state changes and user interactions.
* Add integration tests when flows cross network, persistence, or multiple screens, or when a regression cannot be confidently covered by unit/widget tests alone.
* Fixes are not complete until relevant tests pass locally.

### Search Result Strategy Note

* The current search flow intentionally favors a simpler single-page request with a larger page size.
* If local filtering starts hiding too many items, the next step should be to introduce an opaque pagination token in `packages/lego_catalog` and teach the Flutter search screen to load more pages on scroll.

---

## 6. Phase-by-Phase Vibe Coding Implementation Plan

### Phase 1: Local Ledger Foundation

* Initialize the Drift SQLite database engine.
* Scaffold the high-level models for Sets, Sessions, Intervals, and Completed Bags.
* Write local repository operations to fetch active durations and query un-synced dependencies.

### Phase 2: Reactive Timing Engine

* Construct the Riverpod `ActiveSessionNotifier` to manage state changes.
* Incorporate crash resiliency logic: On app initialization, check for open-ended intervals and automatically resolve them relative to the current time.

### Phase 3: Networking & Integrations
* Define the `LegoCatalogService` interface to support easy swapping of catalog providers.
* Implement the HTTP service to query Rebrickable's endpoint (using a test key initially).
* Future: Deploy a Firebase Serverless Proxy to securely handle Rebrickable requests with App Check/Authentication.
* Build the spreadsheet output service using standard HTTP client calls to process the network payload.
* Wire the automated background thread trigger that runs every time a bag status moves to absolute completion.

### Phase 4: Interface & Polish

* Construct the shell UI elements (Search view, active workspace view, dashboard list views).
* Add micro-helpers, including manual adjustments ("Oops, forgot to start" offset controls) and simple line/bar visual charts for tracking bricks-per-minute trends over months.
