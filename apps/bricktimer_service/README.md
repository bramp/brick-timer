# Brick Timer Functions

Cloud Functions backend for Brick Timer.

## What It Does

This service exposes a small, app-specific catalog API that fronts Rebrickable and keeps the Rebrickable API key server-side.

Current routes:

- `GET /v1/health`
- `GET /v1/sets/search?query=...`
- `GET /v1/sets/{setNumber}`

## App Check

The HTTP function is configured to enforce Firebase App Check so only the Brick Timer app can call it.

## Local Development

The service uses Firebase parameterized configuration for the
`REBRICKABLE_API_KEY` secret.

1. Set the secret value in Firebase (one-time per project):

```sh
firebase functions:secrets:set REBRICKABLE_API_KEY
```

2. Install dependencies from the repository root:

```sh
flutter pub get
```

3. Run the backend locally:

```sh
cd apps/bricktimer_service
# For local runs outside deployed Functions runtime, provide the secret as env
REBRICKABLE_API_KEY=your_key_here dart run bin/server.dart
```

4. Point the app at the local backend when running Flutter:

```sh
flutter run --dart-define=BRICKTIMER_CATALOG_BASE_URL=http://localhost:8080
```

If you need to generate the Firebase Functions manifest used for deployment,
run the Firebase Functions build step from this package after the runtime
scaffolding is in place.
