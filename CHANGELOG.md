# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-XX

### Added

- Initial release of Flutter Flavor Setup
- Complete Android flavor configuration support
- Complete iOS scheme and build configuration support
- Automatic Dart entry point generation
- VSCode/Cursor launch configuration generation
- Smart detection of existing flavors
- SOLID architecture with clean separation of concerns
- Comprehensive CLI interface
- Programmatic API for custom integrations
- Support for both Groovy and Kotlin DSL build files
- Automatic bundle ID and package name management
- Reserved keyword validation
- Project state validation
- Post-setup automation (pod install, flutter clean, pub get)

### Features

- **Android Service**: Product flavor configuration in build.gradle/build.gradle.kts
- **iOS Service**: Xcode project manipulation with scheme generation
- **Dart Service**: Main app file extraction and entry point generation
- **VSCode Service**: Launch configuration management
- **Validators**: Input and project state validation
- **Utils**: String manipulation, file operations, console output
- **Models**: Type-safe configuration objects

### Architecture

- Single Responsibility Principle: Each service handles one concern
- Open/Closed Principle: Extensible without modification
- Liskov Substitution Principle: Interfaces are properly substitutable
- Interface Segregation Principle: Focused, specific interfaces
- Dependency Inversion Principle: Depend on abstractions

### Documentation

- Comprehensive README with examples
- API documentation
- Architecture overview
- Troubleshooting guide
- Contributing guidelines

## [Unreleased]

### Planned

- Web flavor support
- Windows flavor support
- Linux flavor support
- macOS flavor configuration
- Environment variable management
- Flavor-specific assets
- Firebase configuration per flavor
- CI/CD integration examples
- Interactive mode improvements
- Configuration file support (YAML/JSON)
- Dry-run mode
- Rollback functionality
- Automated testing
- GitHub Actions integration
- Documentation website

---

For more information, see the [README](README.md).
