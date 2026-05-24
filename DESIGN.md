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

The visual design brief now lives in [UX_BRIEF.md](UX_BRIEF.md). Keep this document focused on the system, data model, and implementation plan.

At a glance, the app should still follow these product-level UI constraints:

* Large tap targets and high-contrast text for dusty-hands use.
* Fast, low-friction flows that keep search, start, pause, and complete actions within one or two taps.
* Clear loading, empty, offline, and error states with a recovery action on every important screen.
* Material Design 3 as the baseline component and motion system.

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
