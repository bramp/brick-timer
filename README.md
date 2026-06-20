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
2. `apps/bricktimer/.env`

Example `.env` value:

```env
REBRICKABLE_API_KEY=YOUR_API_KEY
```

Example override:

```sh
cd apps/bricktimer
flutter run -d chrome --dart-define=REBRICKABLE_API_KEY=YOUR_API_KEY
```

Warning: This key is then built into the resulting binaries.

### Firebase Setup (Crashlytics, Analytics, App Check)

The app now includes Firebase integration hooks for:

- Crash reporting (`firebase_crashlytics`)
- Usage telemetry (`firebase_analytics`)
- Integrity attestation (`firebase_app_check` with Play Integrity / App Attest)

Current wiring in this repository:

- Dart dependencies: `apps/bricktimer/pubspec.yaml`
- Android Gradle plugins: `apps/bricktimer/android/settings.gradle.kts`
- Android app plugin application: `apps/bricktimer/android/app/build.gradle.kts`
- iOS/macOS native Firebase startup: `AppDelegate.swift`
- Flutter runtime bootstrap: `apps/bricktimer/lib/services/firebase_bootstrap.dart`

1. Install FlutterFire CLI (one-time):

```sh
dart pub global activate flutterfire_cli
```

2. From `apps/bricktimer`, configure Firebase for your platforms:

```sh
cd apps/bricktimer
flutterfire configure
```

This generates platform config files (for example, `google-services.json`,
`GoogleService-Info.plist`) and Firebase options used by Flutter.

If you add/remove platforms later, rerun `flutterfire configure`.

3. Enable Firebase at runtime:

```sh
flutter run -d chrome --dart-define=FIREBASE_ENABLED=true
```

Optional (web App Check):

```sh
flutter run -d chrome \
	--dart-define=FIREBASE_ENABLED=true \
	--dart-define=FIREBASE_APPCHECK_RECAPTCHA_SITE_KEY=YOUR_RECAPTCHA_V3_SITE_KEY
```

Notes:

- In debug mode, App Check uses debug providers.
- In non-debug builds, Android uses Play Integrity and Apple platforms use
  App Attest with DeviceCheck fallback.
- Crashlytics collection is disabled in debug builds by default.

### Keeping Firebase Versions Up To Date

To keep Firebase components current, update all three layers below.

1. FlutterFire Dart packages (`pubspec.yaml`)

Check and upgrade:

```sh
cd apps/bricktimer
flutter pub outdated
flutter pub upgrade firebase_core firebase_analytics firebase_crashlytics firebase_app_check
```

2. Android Gradle plugin versions (`android/settings.gradle.kts`)

The Android plugin versions are pinned in the `plugins` block:

- `com.google.gms.google-services`
- `com.google.firebase.crashlytics`

Review latest versions from official docs and bump both plugin versions in
`apps/bricktimer/android/settings.gradle.kts` when needed.

References:

- Google Services plugin: https://developers.google.com/android/guides/google-services-plugin
- Crashlytics Gradle plugin: https://firebase.google.com/docs/crashlytics/get-started?platform=android

3. Apple pods (iOS/macOS)

After package or config updates, refresh CocoaPods lockfiles:

```sh
cd apps/bricktimer/ios && pod install
cd apps/bricktimer/macos && pod install
```

### Firebase Update Checklist

After any Firebase version change, run this quick verification:

```sh
make deps
make analyze
make test-unit-ci
```

And smoke test Firebase-enabled startup:

```sh
cd apps/bricktimer
flutter run -d macos --dart-define=FIREBASE_ENABLED=true
```

Recommended automation:

- Enable Dependabot or Renovate so PRs are opened automatically for:
	- Dart/Flutter packages (`pubspec.yaml`)
	- Gradle plugins (`*.gradle.kts`, including `android/settings.gradle.kts`)

This is the best way to ensure pinned Android plugin versions do not go stale.

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

### Refresh Generated Flutter Platform Files

You can periodically regenerate Flutter host/platform scaffolding (for example,
after Flutter SDK upgrades):

```sh
make regen-flutter
```

This runs `flutter create` in the existing app directory to refresh generated
native/host files. It then runs a guard check to ensure Android package values
remain:

- `namespace = "net.bramp.bricktimer"`
- `applicationId = "net.bramp.bricktimer"`

If the guard fails, fix `apps/bricktimer/android/app/build.gradle.kts` before
committing.

