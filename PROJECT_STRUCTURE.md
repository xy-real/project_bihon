# Project Structure Documentation

This is a guide to the standardized folder and file organization for the project_bihon Flutter application.

---

## 1. Root Directory Structure

The main application logic should reside within the `/lib` directory. The recommended structure is as follows:

```
lib/
├── core/
├── features/
├── shared/
├── services/
├── routes/
├── config/
├── utils/
├── main.dart
└── app.dart
```

This structure provides clear separation of concerns while maintaining flexibility for feature development and shared resource management.

---

## 2. Folder Contents

### `/core`
Contains core application functionality that is essential to multiple features but is not specific to any single feature. This directory holds critical infrastructure components.

**Typical contents:**
- Error handling and exceptions
- Constants and application configuration
- Logging utilities
- Database setup and initialization
- Authentication logic (if cross-cutting)

### `/features`
Implements the feature-first modular architecture. Each feature is independently developed and tested, following the Clean Architecture pattern with data, domain, and presentation layers.

**Typical contents:**
- Feature-specific implementations
- Each feature has its own data, domain, and presentation layers
- Self-contained and loosely coupled from other features
- Examples: `preparedness`, `alerts`, `notifications`, `profile`

### `/shared`
Contains reusable components, widgets, and utilities that are used across multiple features. This is where common UI components and helper functions live.

**Typical contents:**
- Reusable widgets (buttons, dialogs, custom cards, etc.)
- Shared themes and styles
- Common utilities and helper functions
- Shared models or enums used across features

### `/services`
External service integrations and API clients. This layer handles communication with third-party services, APIs, and external systems.

**Typical contents:**
- HTTP clients (Dio configuration)
- Firebase services
- Location services
- Notification services
- Push notification handling
- Analytics services

### `/routes`
Centralized navigation and route management. All application navigation should be handled through this module.

**Typical contents:**
- Route definitions
- Route generator
- Named route constants
- Deep linking configuration

### `/config`
Application configuration and environment setup. This directory contains configuration files and settings that vary across environments.

**Typical contents:**
- Environment configurations (development, staging, production)
- API endpoints configuration
- Feature flags
- App-wide settings

### `/utils`
General utility functions and helper classes that are generic and not tied to any specific feature.

**Typical contents:**
- Date/time utilities
- String manipulation utilities
- Validation helpers
- Conversion functions
- Extension methods

---

## 3. Feature-Based Architecture

The project follows a **clean architecture pattern** with features organized in a modular, layered structure. Each feature is self-contained and independent, promoting code reusability and making testing easier.

### Feature Directory Structure

```
features/<feature_name>/
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── pages/
    └── widgets/
```

### Layer Explanations

#### **Data Layer**
Responsible for handling all data operations, including API calls, local database access, and data transformation.

- **datasources/**: Contains concrete implementations for fetching data
  - `remote/`: API clients and remote data sources
  - `local/`: Local database or cache implementations
- **models/**: Data transfer objects (DTOs) that map API responses to domain entities
- **repositories/**: Implements abstract repository interfaces from the domain layer, coordinating between datasources

#### **Domain Layer**
Contains the core business logic and rules. This layer is independent of external frameworks and dependencies.

- **entities/**: Pure Dart classes representing the core objects of the feature
- **usecases/**: Business logic operations that orchestrate domain entities and repositories

#### **Presentation Layer**
Handles the user interface and user interaction. This layer is responsible for displaying data and capturing user input.

- **pages/**: Full-screen widgets representing app screens
- **widgets/**: Feature-specific reusable components (not shared across features)
- **controllers/**: State management logic (using Provider, Riverpod, GetX, or similar pattern)

---

## 5. Page and Widget Placement Rules

Proper placement of UI components ensures maintainability and prevents code duplication.

### Pages
- **Location**: `features/<feature_name>/presentation/pages/`
- **Purpose**: Represent complete screens of the application
- **Naming**: Use descriptive names followed by `_page.dart` (e.g., `profile_page.dart`, `alerts_list_page.dart`)
- **Guidelines**: 
  - Each page should correspond to a route in the application
  - Pages should not contain complex business logic—delegate to controllers/providers
  - Pages typically contain a Scaffold or custom layout structure

### Feature-Specific Widgets
- **Location**: `features/<feature_name>/presentation/widgets/`
- **Purpose**: Reusable components used only within the feature
- **Naming**: Use descriptive names followed by `.dart` (e.g., `alert_card.dart`, `preparedness_header.dart`)
- **Guidelines**:
  - These widgets are private to the feature and should not be imported by other features
  - Each widget file should contain a single widget class

### Shared/Reusable Widgets
- **Location**: `shared/widgets/`
- **Purpose**: Components that are used across multiple features
- **Naming**: Use descriptive names followed by `.dart` (e.g., `custom_button.dart`, `confirmation_dialog.dart`)
- **Guidelines**:
  - These widgets are publicly exported and can be imported by any feature
  - Maintain backward compatibility when modifying shared widgets
  - Keep them generic and parameterizable

### Controllers/State Management
- **Location**: `features/<feature_name>/presentation/controllers/`
- **Purpose**: Manage state and business logic for the presentation layer
- **Naming**: Use the feature name followed by `_controller.dart` or `_provider.dart` (e.g., `alerts_provider.dart`)
- **Guidelines**:
  - Controllers should not directly contain UI logic
  - Separate concerns: one controller per page when possible
  - Use dependency injection to pass dependencies

---

## 6. Naming Conventions

Consistent naming conventions make the codebase more readable and maintainable.

### Files
- **Convention**: `snake_case`
- **Examples**:
  - `user_profile_page.dart`
  - `alert_repository.dart`
  - `user_entity.dart`
  - `fetch_alerts_usecase.dart`

### Classes and Types
- **Convention**: `PascalCase`
- **Examples**:
  - `class UserProfilePage extends StatefulWidget {}`
  - `class AlertRepository {}`
  - `class UserEntity {}`
  - `class FetchAlertsUseCase {}`

### Variables and Functions
- **Convention**: `camelCase`
- **Examples**:
  - `int userAge = 25;`
  - `String fetchUserName() {}`
  - `final alertController = AlertController();`
  - `void navigateToProfile() {}`

### Constants
- **Convention**: `camelCase` with optional `final` keyword
- **Examples**:
  - `const String appName = 'Project Bihon';`
  - `const double defaultPadding = 16.0;`
  - `const Duration apiTimeout = Duration(seconds: 30);`

### Booleans
- **Convention**: Start with verb prefixes like `is`, `has`, `should`, `can`
- **Examples**:
  - `bool isLoading = false;`
  - `bool hasError = true;`
  - `bool shouldRefresh = false;`
  - `bool canProceed = true;`

---

## 7. Navigation Structure

Centralized navigation management ensures consistent navigation patterns and makes deep linking easier.

### Route Definition
All routes should be defined in `routes/app_routes.dart` as constants:

```dart
class AppRoutes {
  static const String home = '/';
  static const String profile = '/profile';
  static const String alerts = '/alerts';
  static const String preparedness = '/preparedness';
  static const String profileDetail = '/profile/:id';
}
```

### Route Generator
Create a centralized route generator in `routes/route_generator.dart` that handles route generation and navigation:

```dart
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case AppRoutes.profileDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProfileDetailPage(id: id),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        );
    }
  }
}
```

### Navigation Best Practices
- Use named routes for consistency: `Navigator.of(context).pushNamed(AppRoutes.profile)`
- Pass arguments through route settings rather than constructor parameters
- Use the route generator to handle all navigation logic
- Define all routes in a single location for easy maintenance

---

## 8. Development Best Practices

Following these guidelines ensures code quality and maintainability across all features.

### Separation of Concerns
- **Keep UI logic separate from business logic**: UI widgets should only handle presentation. Complex operations should be moved to controllers or usecases.
- **Example**: Do not make API calls directly in a widget. Instead, call a usecase through a controller/provider.

### Avoid Anti-Patterns
- ❌ **Never** place API calls inside widgets
- ❌ **Never** share state between features without using a service
- ❌ **Never** import from another feature's presentation layer
- ❌ **Never** hardcode API endpoints or configuration values

### Modularity
- **Keep features independent**: Features should not depend on each other's presentation or domain layers
- **Reuse through repositories**: If data is shared between features, abstract it into a service or cross-feature repository
- **Use services for cross-cutting concerns**: Authentication, logging, and analytics should be accessed through services

### Code Organization
- **One widget per file**: Each Dart file should contain a single widget class (with potential helper classes)
- **Group related imports**: Organize imports in the following order:
  1. Dart imports
  2. Package imports
  3. Relative imports (from project)
  4. Local imports (from same package)

### Testing
- **Write tests alongside features**: Place tests in a `test/` directory mirroring the `lib/` structure
- **Test business logic**: Focus integration and unit tests on usecases, repositories, and controllers
- **Use mocks carefully**: Create mock implementations of services and datasources for testing

### Error Handling
- **Create custom exceptions**: Define feature-specific exceptions in the domain layer
- **Handle errors gracefully**: Use error states in controllers to provide user feedback
- **Log errors appropriately**: Use the logging utility from `/core` for debugging

---

## 9. Example Feature Structure

### Alerts Feature

Here is a complete example of how the `alerts` feature should be organized:

```
features/alerts/
├── data/
│   ├── datasources/
│   │   ├── alerts_local_datasource.dart
│   │   └── alerts_remote_datasource.dart
│   ├── models/
│   │   ├── alert_model.dart
│   │   └── alert_response_model.dart
│   └── repositories/
│       └── alerts_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── alert_entity.dart
│   └── usecases/
│       ├── get_all_alerts_usecase.dart
│       ├── get_alert_by_id_usecase.dart
│       └── delete_alert_usecase.dart
└── presentation/
    ├── controllers/
    │   ├── alerts_provider.dart
    │   └── alert_detail_provider.dart
    ├── pages/
    │   ├── alerts_list_page.dart
    │   └── alert_detail_page.dart
    └── widgets/
        ├── alert_card.dart
        ├── alert_filter_widget.dart
        └── alert_status_indicator.dart
```

### Key Files Explained

**`alert_entity.dart`** (Domain Entity):
```dart
class AlertEntity {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final AlertStatus status;

  AlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });
}
```

**`alert_model.dart`** (Data Model):
```dart
class AlertModel extends AlertEntity {
  AlertModel({
    required String id,
    required String title,
    required String description,
    required DateTime createdAt,
    required AlertStatus status,
  }) : super(
    id: id,
    title: title,
    description: description,
    createdAt: createdAt,
    status: status,
  );

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      status: AlertStatus.values.byName(json['status']),
    );
  }
}
```

**`get_all_alerts_usecase.dart`** (Domain UseCase):
```dart
class GetAllAlertsUseCase {
  final AlertsRepository repository;

  GetAllAlertsUseCase({required this.repository});

  Future<List<AlertEntity>> call() async {
    return await repository.getAllAlerts();
  }
}
```

**`alerts_provider.dart`** (State Management):
```dart
final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  final repository = ref.watch(alertsRepositoryProvider);
  return AlertsNotifier(repository);
});

class AlertsNotifier extends StateNotifier<AlertsState> {
  final AlertsRepository repository;

  AlertsNotifier(this.repository) : super(const AlertsState.initial());

  Future<void> fetchAlerts() async {
    state = const AlertsState.loading();
    try {
      final alerts = await repository.getAllAlerts();
      state = AlertsState.success(alerts);
    } catch (e) {
      state = AlertsState.error(e.toString());
    }
  }
}
```

**`alerts_list_page.dart`** (Presentation Page):
```dart
class AlertsListPage extends ConsumerWidget {
  const AlertsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        success: (alerts) => ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) => AlertCard(alert: alerts[index]),
        ),
        error: (message) => Center(child: Text('Error: $message')),
      ),
    );
  }
}
```

### Preparedness Feature

For reference, the `preparedness` feature would follow an identical pattern:

```
features/preparedness/
├── data/
│   ├── datasources/
│   │   ├── preparedness_local_datasource.dart
│   │   └── preparedness_remote_datasource.dart
│   ├── models/
│   │   └── preparedness_item_model.dart
│   └── repositories/
│       └── preparedness_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── preparedness_entity.dart
│   └── usecases/
│       ├── get_preparedness_items_usecase.dart
│       └── update_preparedness_item_usecase.dart
└── presentation/
    ├── controllers/
    │   └── preparedness_provider.dart
    ├── pages/
    │   ├── preparedness_list_page.dart
    │   └── preparedness_detail_page.dart
    └── widgets/
        ├── preparedness_card.dart
        └── preparedness_checklist_widget.dart
```

---

## Summary

This structure provides a scalable, maintainable, and professional foundation for developing the project_bihon application. By adhering to these guidelines, all contributors ensure that:

- New features can be added quickly and independently
- Code is easy to locate and understand
- Reusable components are properly shared
- Testing is straightforward and comprehensive
- The codebase grows in a controlled and organized manner

When in doubt, refer to existing features in the codebase that follow this structure as a reference, and discuss any deviations with the team lead.

---

**Document Version**: 1.0  
**Last Updated**: March 09, 2026  
**Maintained By**: Daniel Catoy
