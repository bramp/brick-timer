# Architecture & Design Philosophy

This document explains the design principles and layered architecture of the `lego_catalog` package.

## Directory Structure

```
lib/src/
  backends/                              ← Backend implementations
    lego_catalog_backend.dart            ← Public backend interface
    bricktimer/                          ← Brick Timer backend package
      bricktimer_backend.dart            ← Business logic & domain mapping
      bricktimer_models.dart             ← Data Transfer Objects (DTOs)
    rebrickable/                         ← Rebrickable backend package
      rebrickable_backend.dart           ← Business logic, filtering, domain mapping
      lego_theme.dart                    ← Domain models
      search_filter_policy.dart          ← Filtering logic
      theme_exclusion_resolver.dart      ← Theme resolution strategy
  http/                                  ← Shared HTTP infrastructure
    catalog_api_client.dart              ← Shared catalog HTTP client
    catalog_http_config.dart             ← Grouped HTTP configuration
  models/                                ← Public domain models
    lego_set.dart
  errors/                                ← Custom exception types
    catalog_http_exception.dart
```

### Design Rationale

- **`backends/`**: Groups all backend implementations. Backend-specific logic stays here.
- **`http/`**: Shared HTTP infrastructure (Dio, retry, timeouts). Not backend-specific, so lives outside `backends/`.
- **Each backend has its own subdirectory**: `bricktimer/` and `rebrickable/` each contain their implementation and interfaces, keeping related code together.
- **Backend interface at top level**: `lego_catalog_backend.dart` is the primary contract all backends implement.

## Core Philosophy: Separation of Concerns

The package follows a **layered architecture** that separates distinct concerns:

1. **Transport Layer**: HTTP communication, retries, error handling
2. **Backend Layer**: Business logic, filtering, domain model mapping

This separation ensures:
- **Testability**: Each layer can be tested independently
- **Maintainability**: Changes to one layer don't cascade into others
- **Extensibility**: New backends can be added without modifying existing code
- **Reusability**: Transport infrastructure can be shared across implementations

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
│              (e.g., Flutter App, Cloud Function)                │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│         Backend Layer (LegoCatalogBackend interface)            │
│  ┌──────────────────┐        ┌──────────────────────────────┐  │
│  │ BrickTimerBackend│        │ RebrickableBackend           │  │
│  │                  │        │  - Theme filtering           │  │
│  │  - Simple mapping│        │  - Advanced search params    │  │
│  │    (no filtering)│        │  - Results aggregation       │  │
│  └────────┬─────────┘        └──────────────┬───────────────┘  │
└───────────┼──────────────────────────────────┼──────────────────┘
            │                                  │
            ▼                                  ▼
┌─────────────────────────┐      ┌──────────────────────────────┐
│      Backend Composition Layer        │
├───────────────────────────────────────┤
│BrickTimerBackend + CatalogApiClient   │
│RebrickableBackend + CatalogApiClient  │
└────────────────────────┬──────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│        Transport Layer (CatalogApiClient)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │        Shared HTTP Infrastructure                        │  │
│  │  - Dio client setup & lifecycle                         │  │
│  │  - Retry logic with exponential backoff                 │  │
│  │  - Per-request timeout configuration                    │  │
│  │  - HTTP status code validation                          │  │
│  │  - Error translation to domain exceptions               │  │
│  │  - JSON payload validation                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           │
           ▼
        ┌─────────────────┐    ┌──────────────────┐
        │  Brick Timer    │    │   Rebrickable    │
        │  HTTP API       │    │   HTTP API       │
        └─────────────────┘    └──────────────────┘
```

## Layer Details

### 1. Backend Layer: `LegoCatalogBackend` Interface

**Responsibility**: Define the contract for catalog search operations.

```dart
abstract class LegoCatalogBackend {
  Future<List<LegoSetSummary>> searchSets(String query, {int pageSize = 20});
  Future<LegoSetDetails?> getSetDetails(String setNumber);
}
```

This is the public API that applications depend on. It abstracts away:
- Which backend is being used
- How data is fetched or processed
- Implementation details

### 2. Backend Composition Layer

Both backends compose a shared concrete transport helper (`CatalogApiClient`) and keep domain mapping/filtering in backend methods.

#### `BrickTimerBackend` + `CatalogApiClient`
Brick Timer uses a simplified shape:
- `BrickTimerBackend` contains domain mapping and minimal input normalization
- `CatalogApiClient` (concrete transport helper) handles HTTP transport
- DTO parsing remains in `bricktimer_models.dart`

#### `RebrickableBackend` + `CatalogApiClient`
Returns **raw JSON maps**. This is more flexible because:
- Complex filtering happens at the backend layer
- The API response doesn't fully align with business requirements
- Theme exclusion and descendant resolution happens in the backend

`RebrickableBackend` keeps raw-map search processing and theme traversal logic,
while `CatalogApiClient` handles HTTP concerns.

### 3. Transport Layer: `CatalogApiClient`

**Responsibility**: Shared HTTP infrastructure for all backends.

```dart
class CatalogApiClient {
  // HTTP client lifecycle
  Dio get dio;
  void dispose();
  
  // Common request handling
  Future<RequestOptions> buildRequestOptions();
  Map<String, dynamic> asJsonMap(Object? data, {required String operation});
  void throwOnUnexpectedStatus(Response<Object> response, String operation);
  CatalogHttpException toCatalogHttpException(DioException error, String operation);
}
```

This shared client eliminates duplication by providing:
- Dio setup with retry policy (exponential backoff)
- Per-request timeout and header injection
- Standardized error handling and translation
- Response validation and JSON parsing

## Specific Backend Implementations

### BrickTimerBackend

**Data Flow**:
1. Backend receives search query from app
2. Calls `CatalogApiClient.getJsonResults()`
3. Parses `List<BrickTimerLegoSetSummary>` (DTOs)
4. Maps each DTO to `LegoSetSummary` (domain model)
5. Returns domain models to app

**Key Feature**: Zero business logic filtering—simple pass-through mapping.

**HTTP Configuration**: Uses `CatalogHttpConfig` for timeout and retry settings:
```dart
final backend = BrickTimerBackend(
  baseUrl: 'https://bricktimer.example.com',
  httpConfig: const CatalogHttpConfig(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 10),
    retries: 3,
    initialRetryDelay: Duration(milliseconds: 250),
  ),
);
```

**Implementation**: `BrickTimerBackend` composes `CatalogApiClient`

### RebrickableBackend

**Data Flow**:
1. Backend receives search query from app
2. Builds query parameters with filtering rules
3. Calls `CatalogApiClient.getJsonResults()`
4. Gets `List<Map<String, dynamic>>` (raw JSON)
5. Applies theme filtering (resolves descendant theme exclusions)
6. Maps filtered results to `LegoSetSummary` (domain models)
7. Returns domain models to app

**Key Features**:
- Theme filtering with descendant resolution (requires separate API call)
- Configurable exclusion rules: `Set<int> excludedThemeRootIds`
- Default exclusions: Gear (501) and Books (497)—non-buildable items

**HTTP Configuration**: Uses `CatalogHttpConfig` for timeout and retry settings:
```dart
final backend = RebrickableBackend(
  apiKey: 'your-api-key',
  httpConfig: const CatalogHttpConfig(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    sendTimeout: Duration(seconds: 10),
    retries: 3,
    initialRetryDelay: Duration(milliseconds: 250),
  ),
);
```

**Implementation**: `RebrickableBackend` composes `CatalogApiClient`

## Why This Architecture Matters

### 1. **Testability**

Without interfaces, testing requires mocking HTTP via `Dio.httpClientAdapter`:

```dart
// Old way: Mock HTTP transport directly
final adapter = _MockAdapter((request) async { ... });
final dio = Dio()..httpClientAdapter = adapter;
final backend = BrickTimerBackend(baseUrl: '...', dio: dio);
```

With interfaces, you can create simple fakes:

```dart
// New way: Implement interface with test data
final backend = BrickTimerBackend(
  baseUrl: 'https://bricktimer.example.com',
  dio: Dio()..httpClientAdapter = fakeAdapter,
);
```

This makes:
- Tests clearer (no HTTP mocking logic)
- Tests faster (no serialization/parsing overhead)
- Business logic testable in isolation

### 2. **Extensibility**

Adding a new backend (e.g., `LocalCatalogBackend` with cached data):

```dart
final backend = BrickTimerBackend(
  baseUrl: 'https://bricktimer.example.com',
  dio: localCacheBackedDio,
);
```

The backend layer doesn't care whether data comes from HTTP or cache—it only knows the interface.

### 3. **Reusability**

The shared `CatalogApiClient` eliminates ~150 lines of duplicate HTTP boilerplate:
- Retry logic
- Timeout handling  
- Error translation
- Response validation

Backends compose `CatalogApiClient` for endpoint calls.

### 4. **Maintainability**

Changes to HTTP handling (retry strategy, timeout defaults, error messages) happen in one place and benefit both backends.

## Design Patterns

### 1. **Strategy Pattern**
Backends implement different strategies for filtering and mapping. The app chooses which strategy to use via dependency injection.

### 2. **Adapter Pattern**
`CatalogApiClient` adapts Dio into a simpler, application-specific interface.

### 3. **Dependency Injection**
Backends accept remote implementations in constructors:

```dart
// Constructor injection (flexible for testing)
final backend = BrickTimerBackend.from(remoteMock);

// Factory constructor (convenient for production)
final backend = BrickTimerBackend(baseUrl: '...');
```

### 4. **Transfer Object (DTO)**
`BrickTimerLegoSetSummary` and `BrickTimerLegoSetDetails` are DTOs that map API payloads to domain models. This isolates the domain from API changes.

## Adding a New Backend

To add a new backend:

1. **Create a remote interface**:
   ```dart
   abstract class YourCatalogRemote {
     Future<List<YourSetSummary>> searchSets({...});
     Future<YourSetDetails?> getSetDetails(String setNumber);
   }
   ```

2. **Compose the shared transport client** (`CatalogApiClient`):
   ```dart
   final client = CatalogApiClient(
     defaultHeaders: const {'Accept': 'application/json'},
   );
   ```

3. **Implement the backend interface**:
   ```dart
   class YourBackend implements LegoCatalogBackend {
     final YourCatalogRemote _remote;
     
     @override
     Future<List<LegoSetSummary>> searchSets(String query, {int pageSize = 20}) async {
       final dtos = await _remote.searchSets(query: query, pageSize: pageSize);
       return dtos.map((dto) => dto.toDomain()).toList();
     }
   }
   ```

4. **Register in your DI container** or app setup.

No existing code needs to change.

## Key Decisions & Trade-offs

### Why not one `CatalogRemote` interface for both backends?

**Rejected**: Using a single interface would require:
- Rebrickable to return DTOs (but its filtering logic needs raw JSON)
- BrickTimer to accept raw JSON (unnecessary overhead)

**Chosen**: Separate interfaces aligned with each backend's needs, resulting in simpler, more focused code.

### Why no separate Rebrickable remote interface?

Rebrickable now follows the same collapsed pattern as BrickTimer: backend owns
domain logic and composes `CatalogApiClient` for transport. Theme resolution is
injected into the resolver via a callback, avoiding transport-class casts.

### Why return DTOs from BrickTimer but raw JSON from and grouped configuration
- **Maintainability**: Changes in one layer don't ripple into others

The design is intentionally pragmatic—not all interfaces have uniform signatures, because each backend's needs are different. This is a feature, not a bug. Configuration is grouped into `CatalogHttpConfig` to reduce parameter sprawl and make it easier to manage HTTP concerns across all backends
**Rebrickable API**: Requires filtering at the backend layer. Raw JSON preserves flexibility for complex filtering logic.

This difference reflects the actual API designs and use cases, not a limitation of the architecture.

## Conclusion

This layered architecture with interface boundaries enables:
- **Clear separation of concerns**: Transport, remote, and backend layers
- **Easy testing**: Mock interfaces instead of HTTP
- **Simple extensibility**: Add backends without modifying existing code
- **Reduced duplication**: Shared HTTP infrastructure
- **Maintainability**: Changes in one layer don't ripple into others

The design is intentionally pragmatic—not all interfaces have uniform signatures, because each backend's needs are different. This is a feature, not a bug.
