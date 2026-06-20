# Brick Timer

A local-first, low-friction Flutter application designed to track what LEGO set you've built, and how long it takes.

by Andrew Brampton ([bramp.net](https://bramp.net)) (c) 2026

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/bramp)

---

## About

The purpose of Brick Timer is to track the exact time it takes to build a LEGO set on a per-bag basis with **zero operational friction**.

## Developer Quickstart

### Prerequisites

- Flutter SDK (Dart 3.11+)
- Make

### Setup

```sh
make deps
```

### Run Locally

Web (Chrome):

```sh
make run DEVICE=chrome
```

macOS desktop:

```sh
make run DEVICE=macos
```

### Rebrickable API Key

The app reads `REBRICKABLE_API_KEY` from:

1. `--dart-define=REBRICKABLE_API_KEY=...` (highest priority)
2. `apps/brick_timer/.env`

Example `.env` value:

```env
REBRICKABLE_API_KEY=YOUR_API_KEY
```

Example override:

```sh
cd apps/brick_timer
flutter run -d chrome --dart-define=REBRICKABLE_API_KEY=YOUR_API_KEY
```

Warning: This key is then built into the resulting binaries.

### Tests

Run all unit tests (app + package):

```sh
make test
```

Run CI-style unit tests:

```sh
make test-unit-ci
```

Run integration tests:

```sh
make test-integration-ci TEST_DEVICE=macos
```

### Code Quality

```sh
make format
make analyze
```

