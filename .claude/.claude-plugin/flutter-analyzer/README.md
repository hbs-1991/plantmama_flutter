# Flutter Analyzer Plugin

Comprehensive Flutter/Dart code analysis plugin for Claude Code. Performs security scanning, performance analysis, and code quality checks.

## Features

- **Security Scanning**: Detect vulnerabilities, exposed API keys, insecure storage, and injection risks
- **Performance Analysis**: Find widget rebuild issues, memory leaks, and async/await problems
- **Code Quality**: Check adherence to Effective Dart, Flutter best practices, and style conventions

## Commands

| Command | Description |
|---------|-------------|
| `/flutter-analyzer:analyze-security` | Scan for security vulnerabilities |
| `/flutter-analyzer:analyze-performance` | Analyze performance issues |
| `/flutter-analyzer:analyze-quality` | Check code quality and patterns |
| `/flutter-analyzer:analyze-all` | Run all analysis types |

## Requirements

- Flutter SDK installed
- `dart analyze` command available in PATH

## Usage

```
/flutter-analyzer:analyze-all
```

The plugin will analyze your entire Flutter project and provide detailed explanations for each issue found, along with suggested fixes.
