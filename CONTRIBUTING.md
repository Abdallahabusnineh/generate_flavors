# Contributing to Flutter Flavor Setup

Thank you for considering contributing to Flutter Flavor Setup! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/flutter_flavor_setup.git
   cd flutter_flavor_setup
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/original/flutter_flavor_setup.git
   ```

## Development Setup

1. Ensure you have Dart SDK installed (version 3.5.4 or higher)
2. Install dependencies:
   ```bash
   dart pub get
   ```
3. Run the linter to ensure code quality:
   ```bash
   dart analyze
   ```

## Project Structure

The project follows SOLID principles and clean architecture:

```
lib/
├── src/
│   ├── models/           # Data models
│   │   ├── flavor_config.dart
│   │   ├── project_config.dart
│   │   └── setup_result.dart
│   ├── services/         # Business logic
│   │   ├── android_service.dart
│   │   ├── dart_service.dart
│   │   ├── ios/          # iOS-specific services
│   │   │   ├── ios_service.dart
│   │   │   ├── podfile_updater.dart
│   │   │   ├── info_plist_updater.dart
│   │   │   ├── xcode_project_updater.dart
│   │   │   ├── xcode_scheme_generator.dart
│   │   │   └── xcode_config_manager.dart
│   │   ├── platform_service.dart
│   │   ├── post_setup_service.dart
│   │   └── vscode_service.dart
│   ├── validators/       # Input validation
│   │   ├── input_validator.dart
│   │   └── project_validator.dart
│   ├── utils/           # Utility functions
│   │   ├── console_utils.dart
│   │   ├── file_utils.dart
│   │   └── string_utils.dart
│   └── cli/             # CLI interface
│       ├── cli_interface.dart
│       └── flavor_setup_command.dart
└── flutter_flavor_setup.dart  # Public API
```

## Coding Standards

### Dart Style Guide

- Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code
- Run `dart analyze` to check for issues
- Maximum line length: 80 characters (recommended)

### Architecture Principles

This project follows SOLID principles:

1. **Single Responsibility**: Each class has one, and only one, reason to change
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Derived classes must be substitutable for their base classes
4. **Interface Segregation**: Many client-specific interfaces are better than one general-purpose interface
5. **Dependency Inversion**: Depend on abstractions, not concretions

### Code Organization

- **Models**: Pure data classes with no business logic
- **Services**: Business logic and platform-specific implementations
- **Validators**: Input and state validation logic
- **Utils**: Reusable utility functions
- **CLI**: User interaction and command orchestration

### Naming Conventions

- Classes: `PascalCase`
- Methods and variables: `camelCase`
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE` for compile-time constants
- Private members: prefix with underscore `_privateMember`
- Files: `snake_case.dart`

### Documentation

- Add doc comments (`///`) for all public APIs
- Include examples in doc comments where applicable
- Keep comments up-to-date with code changes
- Use inline comments sparingly and only when necessary

Example:

````dart
/// Updates the Info.plist to use ${PRODUCT_NAME} for the display name.
///
/// This ensures that flavor-specific app names are properly displayed
/// on iOS devices.
///
/// Example:
/// ```dart
/// final updater = InfoPlistUpdater();
/// await updater.updateInfoPlist();
/// ```
Future<void> updateInfoPlist() async {
  // Implementation
}
````

## Making Changes

### Creating a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Use descriptive branch names:

- `feature/add-web-support`
- `fix/android-gradle-parsing`
- `docs/improve-readme`
- `refactor/service-layer`

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:

```
feat(ios): add support for custom xcconfig files

Implement functionality to create and manage custom
xcconfig files for each flavor configuration.

Closes #123
```

```
fix(android): resolve Kotlin DSL parsing issue

Fix regex pattern to properly handle multiline flavor
definitions in build.gradle.kts files.
```

## Testing

### Manual Testing

Before submitting changes:

1. Test with a fresh Flutter project
2. Test with an existing project that has flavors
3. Test on both macOS and Linux if possible
4. Verify Android and iOS configurations

### Test Checklist

- [ ] Fresh Flutter project setup works
- [ ] Adding flavors to existing project works
- [ ] Multiple flavor setup works correctly
- [ ] Reserved keyword validation works
- [ ] Existing flavor detection works
- [ ] Android Groovy DSL projects work
- [ ] Android Kotlin DSL projects work
- [ ] iOS Xcode project updates work
- [ ] VSCode configuration generation works
- [ ] Dart entry files are created correctly

### Future: Automated Testing

We plan to add automated tests. Contributions to the test suite are highly welcome!

## Submitting Changes

### Pull Request Process

1. Update your fork with the latest upstream changes:

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Push your changes to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

3. Create a Pull Request on GitHub

4. Fill out the PR template completely

5. Ensure all checks pass

### Pull Request Guidelines

- **Title**: Clear and descriptive (e.g., "Add support for Web platform flavors")
- **Description**:
  - What changes were made
  - Why they were made
  - How to test the changes
  - Related issues (if any)
- **Documentation**: Update README and other docs if needed
- **Breaking Changes**: Clearly document any breaking changes
- **Changelog**: Add entry to CHANGELOG.md

### PR Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Manual testing completed
- [ ] No new warnings introduced

## Testing

Describe the testing performed

## Related Issues

Closes #(issue number)
```

## Adding New Features

### Adding Platform Support

To add support for a new platform (e.g., Web, Windows, Linux):

1. Create a new service implementing `PlatformService`:

   ```dart
   class WebService implements PlatformService {
     @override
     String get platformName => 'Web';

     @override
     bool isPlatformAvailable() {
       return Directory('web').existsSync();
     }

     @override
     Future<SetupResult> setupFlavors(ProjectConfig config) async {
       // Implementation
     }
   }
   ```

2. Add the service to `FlavorSetupCommand`
3. Update documentation
4. Add tests

### Adding New Validators

Create validators in `lib/src/validators/`:

```dart
class MyValidator {
  static ValidationResult validateSomething(String? input) {
    if (input == null || input.isEmpty) {
      return ValidationResult.invalid('Error message');
    }
    return ValidationResult.valid(input);
  }
}
```

### Adding Utilities

Add utilities in `lib/src/utils/`:

```dart
class MyUtils {
  MyUtils._(); // Private constructor for utility class

  static String doSomething(String input) {
    // Implementation
    return result;
  }
}
```

## Questions?

- Open an issue for bugs or feature requests
- Start a discussion for general questions
- Contact maintainers via email

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉
