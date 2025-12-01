---
description: Run comprehensive Flutter/Dart analysis covering security, performance, and code quality in one pass
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Comprehensive Flutter/Dart Analysis

Perform a complete analysis of the Flutter project covering all aspects: security, performance, and code quality.

## Analysis Process

### Step 1: Project Overview

First, understand the project structure:

```bash
# Project structure
ls -la lib/ 2>/dev/null || echo "No lib/ directory found"
find lib/ -name "*.dart" | wc -l

# Check pubspec for dependencies
cat pubspec.yaml 2>/dev/null | head -50 || echo "No pubspec.yaml found"
```

### Step 2: Run dart analyze

Execute full static analysis:

```bash
dart analyze --fatal-infos 2>&1 || true
flutter analyze 2>&1 || true
```

Capture all issues reported.

### Step 3: Security Scan

#### Secrets and Credentials
```bash
grep -rn "apiKey\|api_key\|API_KEY\|password\|secret\|token" lib/ --include="*.dart" || true
grep -rn "sk-live\|pk-live\|AIzaSy" lib/ --include="*.dart" || true
```

#### Storage Security
```bash
grep -rn "SharedPreferences.*set.*token\|SharedPreferences.*set.*password" lib/ --include="*.dart" || true
```

#### Network Security
```bash
grep -rn "http://" lib/ --include="*.dart" || true
grep -rn "badCertificateCallback" lib/ --include="*.dart" || true
```

### Step 4: Performance Analysis

#### Widget Rebuilds
```bash
grep -rn "setState" lib/ --include="*.dart" | wc -l
grep -rn "extends StatefulWidget" lib/ --include="*.dart" | wc -l
```

#### Missing Const
```bash
grep -rn "Text(\|Icon(\|SizedBox(\|Padding(" lib/ --include="*.dart" | grep -v "const " | head -20 || true
```

#### Memory Management
```bash
grep -rn "StreamController\|AnimationController\|TextEditingController" lib/ --include="*.dart" || true
grep -rn "void dispose" lib/ --include="*.dart" | wc -l
```

#### List Performance
```bash
grep -rn "ListView(" lib/ --include="*.dart" | grep -v "ListView.builder\|ListView.separated" || true
```

### Step 5: Code Quality Check

#### File Sizes
```bash
find lib/ -name "*.dart" -exec wc -l {} + 2>/dev/null | sort -rn | head -10
```

#### Code Smells
```bash
grep -rn "print(\|debugPrint(" lib/ --include="*.dart" || true
grep -rn "TODO\|FIXME" lib/ --include="*.dart" | wc -l
```

#### Null Safety
```bash
grep -rn "late " lib/ --include="*.dart" | wc -l
grep -rn "!\.\|!\[" lib/ --include="*.dart" | wc -l
```

### Step 6: Deep Dive

Based on initial scans, read specific files that show potential issues:
- Files with security concerns (secrets, insecure storage)
- Large files (>200 lines) for God widget check
- Files with many setState calls

## Output Format

Provide a comprehensive report:

---

## Flutter Analysis Report

### Executive Summary

- **Total Dart files**: X
- **Critical issues**: X
- **High priority**: X
- **Recommendations**: X

---

### Security Findings

#### Critical (Fix Immediately)
[List critical security issues]

#### High Priority
[List high priority security issues]

---

### Performance Findings

#### Widget Optimization
- setState calls found: X
- StatefulWidgets: X
- Potential rebuild issues: [list]

#### Memory Management
- Controllers needing review: [list]
- Dispose methods found: X

---

### Code Quality Findings

#### Structure
- Largest files: [top 5]
- God widget candidates: [list]

#### Code Smells
- Debug statements: X
- TODOs/FIXMEs: X

---

### Prioritized Recommendations

1. **Immediate** - Critical security fixes
2. **Short-term** - Performance optimizations
3. **Medium-term** - Code quality improvements
4. **Long-term** - Architecture considerations

---

## Skill Reference

The flutter-analysis skill provides detailed patterns:
- `references/security-patterns.md` - Security vulnerability catalog
- `references/performance-patterns.md` - Widget optimization guide
- `references/quality-patterns.md` - Effective Dart patterns
