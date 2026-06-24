# Brick Timer Functions

Cloud Functions backend for Brick Timer.

## What It Does

This service exposes a small, app-specific catalog API that fronts Rebrickable and keeps the Rebrickable API key server-side.

## API Reference

### Health Check

```
GET /health
```

Returns the service health status.

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

### Search Sets

```
GET /v1/sets/search?query=<query>
```

Search for LEGO sets by name or keywords.

**Query Parameters:**
- `query` (required): Search term (e.g., "Lamborghini", "Star Wars")

**Search Behavior:**
The search uses sensible defaults optimized for app clients:
- Returns up to 20 results per request

**Response (200 OK):**
```json
{
  "results": [
    {
      "setNumber": "42115-1",
      "name": "Lamborghini Sian FKP 37",
      "totalPieces": 3696,
      "imageUrl": "https://cdn.rebrickable.com/media/sets/42115-1.jpg"
    }
  ]
}
```

**Error Responses:**
- `400 Bad Request`: Missing or empty `query` parameter
- `404 Not Found`: No results found (still returns 200 with empty results array)

### Get Set Details

```
GET /v1/sets/<setNumber>
```

Get detailed information about a specific LEGO set.

**Path Parameters:**
- `setNumber` (required): LEGO set number (e.g., "42115-1")

**Response (200 OK):**
```json
{
  "setNumber": "42115-1",
  "name": "Lamborghini Sian FKP 37",
  "totalPieces": 3696,
  "imageUrl": "https://cdn.rebrickable.com/media/sets/42115-1.jpg"
}
```

**Error Responses:**
- `400 Bad Request`: Missing set number in path
- `404 Not Found`: Set not found in Rebrickable database

## App Check

The HTTP function is configured to enforce Firebase App Check so only the Brick Timer app can call it.

## Current routes:

- `GET /health`
- `GET /v1/sets/search?query=...`
- `GET /v1/sets/{setNumber}`

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
