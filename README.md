# WealthPath

A personal finance tracker app built as part of a Flutter engineering assessment. Implements Clean Architecture, BLoC/Cubit state management, offline-first caching, and optimistic UI updates.

## Setup

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

**Flutter:** 3.41.9 | **Dart:** 3.11.5 | **Bloc:** 9.0.0

## Architecture

Clean Architecture with strict layer separation per feature:

- **Domain** — pure Dart entities, abstract repository interfaces, use cases. No Flutter or third-party dependencies.
- **Data** — models (JSON/Hive serialization), Dio remote sources, Hive local source, repository implementations.
- **Presentation** — BLoC/Cubit, pages, widgets. Reads domain entities only.

Dependency rule: `Presentation → Domain ← Data`. Domain never imports from Data or Presentation.

## Key Decisions

### Spending — Cubit over Bloc

The spending feature has a linear flow (load, paginate, add). Cubit keeps this readable with minimal boilerplate. If the feature grows to include filtering, sorting, or concurrent event streams, migrating to Bloc would give better event traceability.

### Budget — Bloc over Cubit

The budget feature has multiple concurrent event types — load, refresh, paginate, search, and update limit — that can fire in any order. Bloc with `bloc_concurrency` transformers (`restartable`, `droppable`, `sequential`) gives precise control over how overlapping events are handled, which is important for correctness during rapid interactions like scroll-triggered pagination and search.

### Optimistic UI Updates

Both features apply optimistic updates before API responses. In Spending, new records use a `temp_` UUID prefix to safely coexist in the list until the server record replaces them. In Budget, limit changes are emitted immediately to the UI. Both roll back state and cache on failure.

### Cache-First Loading (Budget)

On launch, cached budgets are emitted immediately (`isOffline: true`) so the UI renders without a spinner. A background fetch then updates to fresh data. If the fetch fails and cache is empty, a `BudgetError` is emitted; otherwise the offline state is preserved.

### State Preservation on Errors

`SpendingError` carries `previousItems` and `previousTotal` so the UI continues showing existing data instead of collapsing to a full error screen during pagination or add failures.

### Error Handling

Straightforward `try/catch` with custom `ServerException` and `CacheException` types, rather than `Either<Failure, T>`. This keeps the flow readable at assessment scope. A larger codebase with shared error pipelines would benefit from the functional approach.

### Dependency Injection

`GetIt` with manual registration (no code gen). Repositories and use cases are `LazySingleton` (stateless, shared). Cubit and Bloc are `Factory` (fresh instance per screen).

## Testing

Unit tests cover entities, repository logic, and Cubit/Bloc behaviour across both features.

```bash
flutter test
```

## Assumptions

- API responses always follow the documented schema.
- Currency defaults to USD when not provided by the backend.
- Pagination is fixed at 20 records per request.
- Optimistic updates are only applied after local validation passes.

## Future Improvements

- Extend offline support to the Spending feature using Hive.
- Replace manual GetIt registration with `injectable` for larger scale.
- Add retry logic with exponential backoff in the Dio interceptor.
- Implement functional error handling with `Either<Failure, T>` for better composability in complex flows.
- Extract pagination metadata into a dedicated `PaginationState` value object to keep BLoC states leaner as features grow.
- Replace `LogInterceptor` with a levelled structured logger to prevent sensitive data leaking in production.
- Add integration/widget tests for key user flows.
