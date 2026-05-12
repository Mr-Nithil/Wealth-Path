# WealthPath

WealthPath is a personal finance tracker application developed as part of a Flutter engineering assessment. The project focuses on building a maintainable, scalable, and practical implementation using Clean Architecture, Flutter BLoC/Cubit, and modern Flutter development practices.

The implementation prioritizes engineering decisions that improve code readability, separation of concerns, testability, and user experience while keeping the solution practical for the assessment scope.

This project demonstrates:

- Correct Clean Architecture layer separation with strict dependency rules.
- Readable and idiomatic Dart code with proper null safety throughout.
- Practical BLoC/Cubit state management focused on maintainability over unnecessary complexity.
- Clear separation between UI, business logic, and data handling.
- Dependency injection and modular architecture for scalability and testability.
- Awareness of Flutter widget lifecycle, rebuild behavior, and async state handling.
- Optimistic UI updates, rollback handling, and resilient error management.
- Unit testing across critical layers including Cubit, Repository, and Entities.

## Technology Requirements

- Flutter: 3.41.9
- Dart: 3.11.5
- Bloc: 9.0.0

### Packages

- cupertino_icons: ^1.0.8
- flutter_bloc: ^9.0.0
- equatable: ^2.0.8
- dio: ^5.9.2
- hive: ^2.2.3
- hive_flutter: ^1.1.0
- get_it: ^9.2.1
- injectable: ^2.5.0
- go_router: ^17.2.3
- uuid: ^4.5.3

## Architecture

Clean Architecture with three strict layers per feature:

- **Domain** — pure Dart entities, abstract repository interfaces, use cases. Zero Flutter or
  third-party dependencies.
- **Data** — models (JSON/Hive serialization), Dio remote sources, Hive local source,
  repository implementations.
- **Presentation** — BLoC/Cubit, pages, widgets. Reads domain entities only.

Dependency rule: Presentation → Domain ← Data. Domain never imports from Data or Presentation.

## Assumptions

- API responses always follow the documented schema.
- Currency defaults to USD when not provided by the backend.
- Pagination size is fixed to 20 records per request.
- Optimistic updates are only applied for successful local validation.

## Key Decisions

### Spending Feature

#### Cubit over Bloc

- **Why:** The Spending feature has a relatively linear flow — loading records, pagination, refreshing, and optimistic creation. Since there is no complex event orchestration or multiple parallel event streams, Cubit provides a simpler and more readable solution with significantly less boilerplate compared to Bloc.
- **Trade-off:** If the feature grows to include more advanced workflows such as filtering, sorting, websocket updates, or concurrent actions, migrating to Bloc may provide better event traceability and scalability.

#### Optimistic UI Updates with Temporary IDs

- **Why:** New spending records are inserted into the UI immediately before the API request completes. Temporary IDs generated with UUID allow the optimistic item to exist safely in the list until the backend returns the real record. This creates a faster and smoother user experience.
- **Rollback Strategy:** If the API request fails, the temporary record is removed and the previous total is restored to keep the UI consistent with server state.
- **Trade-off:** Optimistic updates require additional reconciliation logic between temporary and server-generated records, increasing state management complexity slightly.

#### Simple Exception-Based Error Handling (like fpdart)

- **Why:** The feature uses straightforward try-catch handling with custom ServerException objects instead of functional abstractions like Either<Result>. For this assessment-sized feature, this approach keeps the flow easy to follow and avoids unnecessary architectural complexity.
- **Trade-off:** Functional error handling patterns may scale better in larger systems with more complex failure scenarios or shared error pipelines.

#### Repository Abstraction between Data and Domain

- **Why:** The repository layer abstracts data access away from the domain and presentation layers. This keeps the domain independent from Dio, API response structures, and future data-source changes.
- **Benefits:** The architecture allows remote, local cache, or mock implementations to be swapped without affecting business logic or UI layers.

#### Dedicated Dio Client with Centralized Configuration

- **Why:** A dedicated DioClient wrapper centralizes API configuration such as base URL, timeouts, headers, and interceptors. This avoids duplicated networking setup across features.
- **Benefits:** Logging, authentication, retry logic, or global error interceptors can later be added in one place without changing feature code.

#### Dependency Injection with GetIt

- **Why:** All dependencies are registered through a dedicated injection module using get_it, keeping object creation outside the UI layer and improving separation of concerns.
- **Singleton vs Factory Decision:**
- LazySingleton is used for repositories, use cases, and data sources because these are stateless shared services that should have a single reusable instance throughout the app lifecycle.
- Factory is used for SpendingCubit because state management classes should create a fresh state instance whenever a new screen is opened.

#### State Preservation during Errors

- **Why:** When pagination or optimistic updates fail, previously loaded records are preserved inside SpendingError.
- **Benefits:** The UI can continue displaying existing data instead of collapsing into a full error screen, improving user experience and resilience.

#### Equatable for Predictable State Comparisons

- **Why:** Equatable is used for entities and states to simplify value comparison and avoid unnecessary widget rebuilds.
- **Benefits:** Reduces boilerplate while improving predictable state updates in Bloc/Cubit.

#### Unit Testing Critical Layers

- **Why:** Unit tests were added for entities, repository logic, and Cubit behaviour to validate business logic independently from the UI.
- **Benefits:** The UI can continue displaying existing data instead of collapsing into a full error screen, improving user experience and resilience.

### Budget Feature

## Future Improvements

## Setup

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Testing

Run tests with:

```bash
flutter test
```
