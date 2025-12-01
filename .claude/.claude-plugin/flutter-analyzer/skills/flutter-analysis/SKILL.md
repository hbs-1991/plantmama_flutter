---
name: Flutter Analysis
description: This skill should be used when the user asks to "analyze flutter code", "check dart security", "flutter performance issues", "widget optimization", "flutter code quality", "dart best practices", "find flutter vulnerabilities", "memory leaks in flutter", or mentions Flutter/Dart code analysis. Provides comprehensive knowledge of Flutter security vulnerabilities, performance anti-patterns, and code quality standards.
version: 1.0.0
---

# Flutter/Dart Code Analysis

Comprehensive analysis skill for Flutter and Dart codebases covering security, performance, and code quality.

## Overview

This skill enables thorough analysis of Flutter projects by identifying:

1. **Security vulnerabilities** - Exposed secrets, insecure storage, injection risks
2. **Performance issues** - Widget rebuilds, memory leaks, async problems
3. **Code quality problems** - Pattern violations, code smells, style issues

## Analysis Workflow

### Initial Setup

Before performing analysis, run the Flutter/Dart analyzer to gather baseline issues:

```bash
dart analyze --fatal-infos
flutter analyze
```

Parse the output to identify files with existing issues, then perform deeper manual analysis.

### Security Analysis

Scan for these critical security issues in Flutter/Dart code:

#### API Keys and Secrets

Search for hardcoded secrets using patterns:

```dart
// DANGEROUS - Hardcoded keys
const apiKey = "sk-live-xxxxx";
final firebaseConfig = {"apiKey": "AIzaSy..."};

// SAFE - Environment variables or secure storage
final apiKey = const String.fromEnvironment('API_KEY');
final apiKey = await SecureStorage().read(key: 'api_key');
```

Grep patterns to find exposed secrets:
- `apiKey|api_key|API_KEY`
- `password|secret|token`
- `sk-live|pk-live|AIzaSy`
- `firebase.*config`

#### Insecure Storage

Identify improper data storage:

```dart
// DANGEROUS - SharedPreferences for sensitive data
SharedPreferences.getInstance().then((p) => p.setString('token', jwt));

// SAFE - flutter_secure_storage
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: jwt);
```

#### HTTP Security

Check for insecure network calls:

```dart
// DANGEROUS - HTTP without TLS
final response = await http.get(Uri.parse('http://api.example.com'));

// DANGEROUS - Disabled certificate verification
HttpClient()..badCertificateCallback = (cert, host, port) => true;

// SAFE - HTTPS with proper verification
final response = await http.get(Uri.parse('https://api.example.com'));
```

For detailed security patterns, see `references/security-patterns.md`.

### Performance Analysis

Identify performance anti-patterns that cause unnecessary work:

#### Widget Rebuild Issues

Look for setState abuse and missing const:

```dart
// PROBLEMATIC - Rebuilds entire widget tree
void _onTap() {
  setState(() {
    _counter++;
  });
}

// PROBLEMATIC - Missing const
Container(
  child: Text('Static text'),  // Rebuilds every time
)

// BETTER - Const constructors
const Container(
  child: Text('Static text'),  // Never rebuilds
)
```

#### Build Method Anti-Patterns

Check build methods for expensive operations:

```dart
// DANGEROUS - Creating objects in build
Widget build(BuildContext context) {
  final controller = TextEditingController();  // Created every build!
  final expensive = computeExpensiveValue();    // Called every build!

  return TextField(controller: controller);
}

// SAFE - Initialize in initState or use late
late final TextEditingController _controller;

@override
void initState() {
  super.initState();
  _controller = TextEditingController();
}
```

#### Memory Leaks

Identify undisposed resources:

```dart
// MEMORY LEAK - Controller never disposed
class MyWidget extends StatefulWidget {
  final controller = StreamController();  // Never disposed!
}

// CORRECT - Dispose in dispose()
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  super.dispose();
}
```

For detailed performance patterns, see `references/performance-patterns.md`.

### Code Quality Analysis

Apply Effective Dart and Flutter idioms:

#### Null Safety

Ensure proper null handling:

```dart
// POOR - Null assertion without checks
final name = user!.name!;

// BETTER - Null-aware operators
final name = user?.name ?? 'Unknown';

// BEST - Pattern matching (Dart 3+)
if (user case User(:final name)) {
  print(name);
}
```

#### State Management

Check for proper state handling:

```dart
// PROBLEMATIC - Prop drilling
Widget build(context) {
  return ChildA(
    value: value,
    child: ChildB(
      value: value,  // Passing through multiple levels
    ),
  );
}

// BETTER - InheritedWidget, Provider, or Riverpod
final value = context.watch<MyProvider>().value;
```

#### Async/Await Patterns

Verify proper async handling:

```dart
// PROBLEMATIC - Unhandled future
void loadData() {
  fetchData();  // Fire and forget - errors swallowed
}

// PROBLEMATIC - Blocking the UI
final data = await slowOperation();  // In build method!

// CORRECT - FutureBuilder
FutureBuilder<Data>(
  future: _dataFuture,
  builder: (context, snapshot) => ...
)
```

For detailed quality patterns, see `references/quality-patterns.md`.

## Output Format

When reporting issues, structure findings by severity:

### Critical Issues

Security vulnerabilities and crashes. Require immediate attention.

### High Priority

Performance problems affecting user experience. Fix before release.

### Medium Priority

Code quality issues and maintainability concerns. Address in next sprint.

### Low Priority

Style violations and minor improvements. Consider for refactoring.

## Integration with dart analyze

Run `dart analyze` first to capture:
- Type errors
- Lint violations
- Info-level hints

Then augment with manual analysis for:
- Security patterns not caught by static analysis
- Complex performance issues
- Architecture and design concerns

## Additional Resources

### Reference Files

For comprehensive patterns and examples, consult:

- **`references/security-patterns.md`** - Complete security vulnerability catalog
- **`references/performance-patterns.md`** - Widget optimization and memory management
- **`references/quality-patterns.md`** - Effective Dart and Flutter idioms

### Common Grep Patterns

Use these to find issues quickly:

```bash
# Security
grep -r "http://" lib/
grep -r "apiKey\|api_key\|API_KEY" lib/
grep -r "badCertificateCallback" lib/

# Performance
grep -r "setState" lib/
grep -r "StreamController\|AnimationController" lib/

# Quality
grep -r "print(" lib/
grep -r "// TODO\|// FIXME" lib/
```
