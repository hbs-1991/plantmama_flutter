---
description: Scan Flutter/Dart code for security vulnerabilities including exposed secrets, insecure storage, and injection risks
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Security Analysis for Flutter/Dart

Perform comprehensive security scanning of the Flutter project.

## Analysis Process

### Step 1: Run dart analyze

Execute the Dart analyzer to capture baseline issues:

```bash
dart analyze --fatal-infos 2>&1 || true
```

Note any security-related warnings from the output.

### Step 2: Scan for Hardcoded Secrets

Search for exposed API keys, passwords, and tokens:

```bash
# API keys and secrets
grep -rn "apiKey\|api_key\|API_KEY" lib/ --include="*.dart" || true
grep -rn "password\|secret\|token" lib/ --include="*.dart" || true
grep -rn "sk-live\|pk-live\|AIzaSy" lib/ --include="*.dart" || true
```

Read any flagged files to verify if values are actually hardcoded credentials.

### Step 3: Check for Insecure Storage

Look for sensitive data stored insecurely:

```bash
# SharedPreferences with sensitive data
grep -rn "SharedPreferences" lib/ --include="*.dart" || true

# Check what's being stored
grep -rn "setString.*token\|setString.*password\|setString.*key" lib/ --include="*.dart" || true
```

### Step 4: Network Security

Check for HTTP and certificate issues:

```bash
# Unencrypted HTTP
grep -rn "http://" lib/ --include="*.dart" || true

# Disabled certificate validation
grep -rn "badCertificateCallback" lib/ --include="*.dart" || true
```

### Step 5: Input Validation

Look for SQL injection and path traversal risks:

```bash
# Raw SQL queries
grep -rn "rawQuery\|rawInsert\|rawDelete" lib/ --include="*.dart" || true

# File operations with user input
grep -rn "File(" lib/ --include="*.dart" || true
```

### Step 6: WebView Security

Check WebView configurations:

```bash
grep -rn "WebView\|InAppWebView" lib/ --include="*.dart" || true
grep -rn "javascriptMode\|evaluateJavascript" lib/ --include="*.dart" || true
```

## Output Format

Report findings with this structure:

### Critical Issues (Require Immediate Action)

For each critical issue:
- **File**: path/to/file.dart:line
- **Issue**: Description of vulnerability
- **Risk**: What could go wrong
- **Fix**: Specific code change needed

### High Priority Issues

Similar format for high-priority findings.

### Recommendations

General security improvements for the codebase.

## Skill Reference

Load the flutter-analysis skill for detailed security patterns:
- Check `references/security-patterns.md` for comprehensive vulnerability catalog
