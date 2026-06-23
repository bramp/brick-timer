# lego_catalog

Reusable LEGO catalog library with pluggable backends, plus a small CLI for manual API testing.

## What Is In This Package

- Generic backend interface: `LegoCatalogBackend`
- Domain models:
  - `LegoSetSummary`
  - `LegoSetDetails`
- Rebrickable implementation: `RebrickableBackend`
  - Uses `dio` for HTTP
  - Uses `dio_smart_retry` for retry + backoff
  - Configurable timeouts, retries, retry delay, and base URL
  - Theme filtering with descendant resolution
- Brick Timer implementation: `BrickTimerBackend`
  - Simple pass-through catalog service backend
  - Uses shared HTTP infrastructure
  - Designed as a server-side proxy to keep API keys private
- CLI executable: `lego_catalog`

## Library Usage

Import the package:

```dart
import 'package:lego_catalog/lego_catalog.dart';
```

Create a backend and search sets:

```dart
final backend = RebrickableBackend(
  apiKey: 'YOUR_REBRICKABLE_API_KEY',
  retries: 3,
  initialRetryDelay: const Duration(milliseconds: 250),
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 10),
);

final results = await backend.searchSets('Lamborghini');
for (final set in results) {
  print('${set.setNumber}: ${set.name} (${set.totalPieces} pieces)');
}
```

Fetch one set:

```dart
final details = await backend.getSetDetails('42115');
if (details == null) {
  print('Set not found');
} else {
  print(details.toJson());
}
```

## CLI Usage

Run from the repository root (workspace mode):

```bash
dart run lego_catalog --help
```

Search command:

```bash
export REBRICKABLE_API_KEY="your-key"

dart run lego_catalog \
  --backend rebrickable \
  search \
  "Lamborghini"

dart run lego_catalog \
  --backend bricktimer \
  search \
  --base-url "https://bricktimer.example.com" \
  "Lamborghini"
```

Details command:

```bash
dart run lego_catalog \
  --backend rebrickable \
  details \
  "42115"

dart run lego_catalog \
  --backend bricktimer \
  details \
  --base-url "https://bricktimer.example.com" \
  "42115"
```

`--api-key` is optional. If omitted, the CLI reads
`REBRICKABLE_API_KEY` from your environment.

If both are provided, `--api-key` takes precedence.

For `--backend bricktimer`, configure service URL via `--base-url` or
`BRICKTIMER_BASE_URL`.

### Optional CLI Tuning Flags

Both commands support:

- `--base-url`
- `--connect-timeout-ms`
- `--receive-timeout-ms`
- `--send-timeout-ms`
- `--retries`
- `--initial-retry-delay-ms`
- `--log-level` (`all`, `finest`, `finer`, `fine`, `info`, `warning`, `severe`, `shout`, `off`)

You can also set `LOG_LEVEL` in the environment when `--log-level` is not
provided.

Example:

```bash
dart run lego_catalog \
  --backend rebrickable \
  search \
  "Technic" \
  --log-level fine \
  --retries 5 \
  --initial-retry-delay-ms 100 \
  --connect-timeout-ms 8000
```

One-off override without exporting:

```bash
dart run lego_catalog search \
  --backend rebrickable \
  --api-key "override-key" \
  "Technic"
```

## Extending With Other Backends

Implement `LegoCatalogBackend`:

```dart
class MyCatalogBackend implements LegoCatalogBackend {
  @override
  Future<List<LegoSetSummary>> searchSets(String query, {int pageSize = 20}) {
    // TODO: map your API into LegoSetSummary
    throw UnimplementedError();
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) {
    // TODO: map your API into LegoSetDetails
    throw UnimplementedError();
  }
}
```

Then inject it wherever needed (app providers, tests, CLI extensions, etc.).

See [DESIGN.md](DESIGN.md) for detailed architecture documentation.
