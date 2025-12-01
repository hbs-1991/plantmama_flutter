---
description: Check Flutter/Dart code quality including Effective Dart compliance, Flutter idioms, and maintainability patterns
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Code Quality Analysis for Flutter/Dart

Analyze code quality, patterns, and adherence to Effective Dart and Flutter best practices.

## Analysis Process

### Step 1: Run dart analyze

Execute full analysis:

```bash
dart analyze --fatal-infos 2>&1 || true
```

Review all reported issues including info-level hints.

### Step 2: Naming Conventions

Check for naming violations:

```bash
# SCREAMING_CAPS constants (should be lowerCamelCase)
grep -rn "const [A-Z_]\{2,\} =" lib/ --include="*.dart" || true

# Files with wrong naming
find lib/ -name "*.dart" | grep -v "^[a-z_]*\.dart$" || true
```

### Step 3: Null Safety Issues

Find problematic null handling:

```bash
# Excessive late usage
grep -rn "late " lib/ --include="*.dart" || true

# Null assertions that might fail
grep -rn "!\." lib/ --include="*.dart" || true
grep -rn "!\[" lib/ --include="*.dart" || true
```

### Step 4: Widget Structure

Check for God widgets and prop drilling:

```bash
# Large files (potential God widgets)
find lib/ -name "*.dart" -exec wc -l {} + | sort -rn | head -20

# StatefulWidgets (review for complexity)
grep -rn "extends StatefulWidget" lib/ --include="*.dart" || true
```

Read large files to check for:
- Single responsibility violations
- Prop drilling (data passed through many levels)
- Mixed business/UI logic

### Step 5: State Management

Identify state management patterns:

```bash
# Provider usage
grep -rn "context.watch\|context.read\|Provider.of" lib/ --include="*.dart" || true

# setState scope
grep -rn "setState" lib/ --include="*.dart" || true

# InheritedWidget usage
grep -rn "InheritedWidget" lib/ --include="*.dart" || true
```

### Step 6: Code Smells

Find common issues:

```bash
# Debug prints left in code
grep -rn "print(" lib/ --include="*.dart" || true
grep -rn "debugPrint(" lib/ --include="*.dart" || true

# TODO/FIXME comments
grep -rn "TODO\|FIXME" lib/ --include="*.dart" || true

# Magic numbers/strings
grep -rn "EdgeInsets.all([0-9]" lib/ --include="*.dart" || true
grep -rn "Duration(seconds: [0-9]" lib/ --include="*.dart" || true
```

### Step 7: Import Organization

Check import structure:

```bash
# Sample files to check import order
head -30 lib/main.dart 2>/dev/null || true
find lib/ -name "*.dart" -exec head -20 {} \; | head -100
```

### Step 8: Documentation

Check documentation coverage:

```bash
# Public APIs without docs (sample check)
grep -rn "^class \|^enum \|^typedef " lib/ --include="*.dart" | head -20

# Doc comments present
grep -rn "^///" lib/ --include="*.dart" | wc -l
```

### Step 9: Error Handling

Review error handling patterns:

```bash
# Try-catch blocks
grep -rn "try {" lib/ --include="*.dart" || true

# Empty catch blocks
grep -rn "catch.*{[ ]*}" lib/ --include="*.dart" || true

# Generic catch
grep -rn "catch (e)" lib/ --include="*.dart" || true
```

## Output Format

Report findings by category:

### Style Violations

- Naming convention issues
- Import ordering
- Formatting problems

### Maintainability Issues

- God widgets (files >200 lines doing too much)
- Prop drilling detected
- Complex build methods

### Code Smells

- Debug code remaining
- Magic values
- Empty/generic error handling

### Documentation Gaps

- Undocumented public APIs
- Missing file-level documentation

### Recommendations

Prioritized list of improvements.

## Skill Reference

Load the flutter-analysis skill for detailed patterns:
- Check `references/quality-patterns.md` for Effective Dart guide
