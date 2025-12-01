# Flutter Code Quality Patterns

Guide to Effective Dart, Flutter idioms, and maintainable code patterns.

## Effective Dart Principles

### Naming Conventions

**Classes, enums, typedefs**: UpperCamelCase
```dart
class HttpRequest { ... }
enum ConnectionState { ... }
typedef Callback = void Function(int);
```

**Variables, functions, parameters**: lowerCamelCase
```dart
var itemCount = 0;
void handleClick() { ... }
```

**Constants**: lowerCamelCase (NOT SCREAMING_CAPS)
```dart
// GOOD
const defaultTimeout = Duration(seconds: 30);

// BAD
const DEFAULT_TIMEOUT = Duration(seconds: 30);
```

**Libraries, packages, files**: lowercase_with_underscores
```dart
library my_library;
import 'package:my_package/file_name.dart';
```

### Type Annotations

**Prefer**: Infer types for local variables, annotate public APIs.

```dart
// Local variables - infer
var count = 0;
final items = <String>[];

// Public APIs - annotate
int calculateTotal(List<Item> items) {
  return items.fold(0, (sum, item) => sum + item.price);
}

// Don't redundantly annotate
// BAD
final Map<String, int> scores = <String, int>{};
// GOOD
final scores = <String, int>{};
```

### Null Safety

**Avoid late unless necessary**:
```dart
// Prefer nullable with null check
String? _name;

void useName() {
  if (_name case final name?) {
    print(name);
  }
}

// Use late only when initialization is guaranteed
late final String name = computeName();  // Lazy initialization
```

**Prefer null-aware operators**:
```dart
// BAD
String displayName;
if (user != null && user.name != null) {
  displayName = user.name;
} else {
  displayName = 'Guest';
}

// GOOD
final displayName = user?.name ?? 'Guest';
```

**Avoid nullable types when possible**:
```dart
// BAD - nullable when always initialized
class User {
  String? name;  // Set in constructor but nullable
  User(this.name);
}

// GOOD - non-nullable for required fields
class User {
  final String name;
  User(this.name);
}
```

### Imports

**Order**: dart:, package:, relative imports, each group alphabetized.

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import 'utils.dart';
```

**Prefer relative imports** within same package:
```dart
// In lib/src/widgets/button.dart
// BAD
import 'package:my_app/src/models/theme.dart';
// GOOD
import '../models/theme.dart';
```

## Flutter-Specific Patterns

### Widget Design

**Single responsibility**: Each widget does one thing well.

```dart
// BAD - Widget does too much
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar logic
        // Name display logic
        // Bio editing logic
        // Settings buttons
        // ... 200 lines
      ],
    );
  }
}

// GOOD - Composed from focused widgets
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(),
        UserNameDisplay(),
        UserBioEditor(),
        UserSettingsButtons(),
      ],
    );
  }
}
```

**Prefer composition over inheritance**:
```dart
// BAD - Extending widgets
class MyButton extends ElevatedButton { ... }

// GOOD - Wrap and customize
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: _myButtonStyle,
      ...
    );
  }
}
```

### State Management Selection

Choose based on scope and complexity:

| Scope | Complexity | Recommended |
|-------|------------|-------------|
| Single widget | Simple | setState |
| Widget subtree | Simple | InheritedWidget |
| Widget subtree | Moderate | Provider |
| App-wide | Complex | Riverpod, Bloc |
| App-wide | Very complex | Riverpod + freezed |

**setState red flags** (time to upgrade):
- Passing callbacks through multiple widget levels
- Multiple widgets need same state
- Complex state logic with many conditions

### BuildContext Usage

**Don't store context**:
```dart
// DANGEROUS
BuildContext? _savedContext;
void save() { _savedContext = context; }

// SAFE - Always use context in same sync frame or check mounted
```

**Access inherited widgets correctly**:
```dart
// For Theme, MediaQuery - use static methods
final theme = Theme.of(context);
final size = MediaQuery.sizeOf(context);  // More efficient than .of()

// For Provider
final user = context.watch<UserProvider>().user;  // Rebuilds
final user = context.read<UserProvider>().user;   // No rebuild
```

### Keys Usage

**When to use keys**:
```dart
// In lists with reorderable/removable items
ListView(
  children: items.map((item) =>
    ListTile(key: ValueKey(item.id), title: Text(item.name))
  ).toList(),
)

// With AnimatedSwitcher, PageView
AnimatedSwitcher(
  child: _showFirst
    ? WidgetA(key: ValueKey('a'))
    : WidgetB(key: ValueKey('b')),
)

// To force widget recreation
UserProfile(key: ValueKey(userId))  // Recreates when userId changes
```

### Async Patterns

**FutureBuilder initialization**:
```dart
class _MyState extends State<MyWidget> {
  late final Future<Data> _future = _loadData();

  Future<Data> _loadData() async {
    return await repository.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorWidget(snapshot.error!);
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return DataView(data: snapshot.data!);
      },
    );
  }
}
```

**StreamBuilder with proper disposal**:
```dart
class _MyState extends State<MyWidget> {
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen(_handleData);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

## Code Smells to Detect

### Prop Drilling

**Smell**: Passing data through many widget levels.

```dart
// SMELL
Parent(
  child: Child(
    value: value,
    child: GrandChild(
      value: value,  // Just passing through!
      child: GreatGrandChild(value: value),
    ),
  ),
)
```

**Solution**: Use InheritedWidget, Provider, or Riverpod.

### God Widget

**Smell**: Widget with too many responsibilities (>200 lines).

**Solution**: Extract focused sub-widgets.

### Long Build Methods

**Smell**: Build method with complex logic.

```dart
// SMELL
Widget build(BuildContext context) {
  final processedData = data.map(...).where(...).toList();
  final sorted = processedData..sort(...);
  // ... 50 lines of logic
  return Column(...);
}
```

**Solution**: Move logic to getters, methods, or computed properties.

### Mixed Business and UI Logic

**Smell**: Business logic in widgets.

```dart
// SMELL
class _OrderState extends State<OrderWidget> {
  void _submitOrder() {
    // Validation logic
    // API calls
    // Error handling
    // State updates
  }
}
```

**Solution**: Separate concerns (repository, service, provider/bloc).

### Hard-coded Values

**Smell**: Magic numbers and strings in widgets.

```dart
// SMELL
Padding(
  padding: EdgeInsets.all(16),  // Magic number
  child: Text('Submit'),        // Hard-coded string
)
```

**Solution**: Use theme, constants, or localization.

```dart
Padding(
  padding: EdgeInsets.all(AppSpacing.md),
  child: Text(context.l10n.submitButton),
)
```

## Error Handling Patterns

### Typed Exceptions

```dart
// Define specific exceptions
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  NetworkException(this.message, {this.statusCode});
}

// Catch specifically
try {
  await api.fetch();
} on NetworkException catch (e) {
  showNetworkError(e.message);
} on FormatException catch (e) {
  showParseError(e);
} catch (e, stack) {
  logUnexpectedError(e, stack);
}
```

### Result Types

```dart
// Instead of throwing, return Result
sealed class Result<T> {}
class Success<T> extends Result<T> {
  final T value;
  Success(this.value);
}
class Failure<T> extends Result<T> {
  final Exception error;
  Failure(this.error);
}

// Usage
Future<Result<User>> getUser(String id) async {
  try {
    final user = await api.fetchUser(id);
    return Success(user);
  } catch (e) {
    return Failure(e as Exception);
  }
}

// Consumption
final result = await getUser('123');
switch (result) {
  case Success(:final value):
    showUser(value);
  case Failure(:final error):
    showError(error);
}
```

## Testing Patterns

### Widget Testing Structure

```dart
testWidgets('shows loading then data', (tester) async {
  // Arrange
  final mockRepo = MockRepository();
  when(mockRepo.fetch()).thenAnswer((_) async => testData);

  // Act
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repoProvider.overrideWithValue(mockRepo)],
      child: const MyApp(),
    ),
  );

  // Assert - loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Act - wait for async
  await tester.pumpAndSettle();

  // Assert - data state
  expect(find.text('Test Data'), findsOneWidget);
});
```

### Golden Tests

```dart
testWidgets('matches golden', (tester) async {
  await tester.pumpWidget(const MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

## Documentation Standards

### Public API Documentation

```dart
/// Fetches user data from the remote API.
///
/// Throws [NetworkException] if the request fails.
/// Throws [AuthException] if the token is invalid.
///
/// Example:
/// ```dart
/// final user = await userRepository.getUser('123');
/// print(user.name);
/// ```
Future<User> getUser(String id) async { ... }
```

### Inline Comments

```dart
// WHY comments, not WHAT comments
// BAD
i++; // Increment i

// GOOD
i++; // Skip header row in CSV
```

## Checklist

Code quality review checklist:

- [ ] Follows Dart naming conventions
- [ ] Proper null safety usage
- [ ] Imports correctly ordered
- [ ] Widgets have single responsibility
- [ ] No prop drilling (data passing through multiple levels)
- [ ] No god widgets (>200 lines)
- [ ] Build methods are simple
- [ ] Business logic separated from UI
- [ ] No hard-coded magic values
- [ ] Errors handled with proper types
- [ ] Public APIs documented
- [ ] Tests cover critical paths
