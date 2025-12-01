---
description: Analyze Flutter/Dart code for performance issues including widget rebuilds, memory leaks, and async anti-patterns
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Performance Analysis for Flutter/Dart

Identify performance bottlenecks and optimization opportunities in the Flutter project.

## Analysis Process

### Step 1: Run dart analyze

Execute the Dart analyzer for baseline issues:

```bash
dart analyze --fatal-infos 2>&1 || true
```

### Step 2: Widget Rebuild Issues

Find excessive setState usage and missing const:

```bash
# setState calls - review scope
grep -rn "setState" lib/ --include="*.dart" || true

# StatefulWidgets to check
grep -rn "extends StatefulWidget" lib/ --include="*.dart" || true
```

For each StatefulWidget found, read the file and check:
- Is setState scoped to the smallest possible widget?
- Could state be extracted to a smaller child widget?

### Step 3: Missing Const Constructors

Find widgets that should be const:

```bash
# Common widgets that are often not const
grep -rn "Text(" lib/ --include="*.dart" | grep -v "const Text" || true
grep -rn "Icon(" lib/ --include="*.dart" | grep -v "const Icon" || true
grep -rn "SizedBox(" lib/ --include="*.dart" | grep -v "const SizedBox" || true
grep -rn "Padding(" lib/ --include="*.dart" | grep -v "const Padding" || true
```

### Step 4: Build Method Anti-Patterns

Check for expensive operations in build methods:

```bash
# Controllers created in build
grep -rn "TextEditingController()\|AnimationController(" lib/ --include="*.dart" || true

# Look for method calls in build that might be expensive
grep -rn "Widget build" lib/ --include="*.dart" -A 20 || true
```

Read files to verify controllers are created in initState, not build.

### Step 5: Memory Leaks

Find undisposed resources:

```bash
# Controllers that need disposal
grep -rn "StreamController\|AnimationController\|TextEditingController\|ScrollController\|FocusNode" lib/ --include="*.dart" || true

# Check for dispose methods
grep -rn "void dispose" lib/ --include="*.dart" || true
```

Cross-reference to ensure all controllers have matching dispose calls.

### Step 6: List Performance

Check for inefficient list rendering:

```bash
# ListView without builder
grep -rn "ListView(" lib/ --include="*.dart" | grep -v "ListView.builder\|ListView.separated" || true

# Large lists
grep -rn "children:" lib/ --include="*.dart" -A 5 || true
```

### Step 7: Async Issues

Find FutureBuilder anti-patterns:

```bash
# FutureBuilder - check if future is created properly
grep -rn "FutureBuilder" lib/ --include="*.dart" -A 5 || true

# compute() for heavy operations
grep -rn "compute(" lib/ --include="*.dart" || true
```

### Step 8: Image Optimization

Check image loading:

```bash
# Images without size constraints
grep -rn "Image.network\|Image.asset" lib/ --include="*.dart" || true
grep -rn "cacheWidth\|cacheHeight" lib/ --include="*.dart" || true
```

## Output Format

Report findings organized by impact:

### Critical Performance Issues

Issues causing noticeable lag or crashes:
- **File**: path/to/file.dart:line
- **Issue**: What's happening
- **Impact**: User-visible effect
- **Fix**: How to resolve

### Widget Rebuild Optimizations

Opportunities to reduce unnecessary rebuilds:
- Which widgets rebuild too often
- How to scope setState better
- Where to add const

### Memory Management

Resources needing disposal and potential leaks.

### Recommendations

General performance improvements prioritized by impact.

## Skill Reference

Load the flutter-analysis skill for detailed patterns:
- Check `references/performance-patterns.md` for optimization techniques
