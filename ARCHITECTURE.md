# Architecture Documentation

This document describes the architecture and design decisions of Flutter Flavor Setup.

## Table of Contents

- [Overview](#overview)
- [SOLID Principles](#solid-principles)
- [Layer Architecture](#layer-architecture)
- [Design Patterns](#design-patterns)
- [Data Flow](#data-flow)
- [Extension Points](#extension-points)

## Overview

Flutter Flavor Setup follows a clean, modular architecture based on SOLID principles. The codebase is organized into distinct layers with clear responsibilities and minimal coupling.

## SOLID Principles

### Single Responsibility Principle (SRP)

Each class has one, and only one, reason to change:

- **Models**: Only concerned with data structure
- **Services**: Handle one specific platform or task
- **Validators**: Focus on validation logic only
- **Utils**: Provide specific utility functions
- **CLI**: Handle user interaction only

Example:

```dart
// ✅ Good - Single responsibility
class AndroidService implements PlatformService {
  Future<SetupResult> setupFlavors(ProjectConfig config) async {
    // Only handles Android flavor setup
  }
}

// ❌ Bad - Multiple responsibilities
class SetupService {
  Future<void> setupAndroid() {}
  Future<void> setupIOS() {}
  Future<void> setupDart() {}
  Future<void> validateInput() {}
}
```

### Open/Closed Principle (OCP)

Open for extension, closed for modification:

```dart
// Abstract interface - closed for modification
abstract class PlatformService {
  Future<SetupResult> setupFlavors(ProjectConfig config);
  bool isPlatformAvailable();
  String get platformName;
}

// Concrete implementations - open for extension
class AndroidService implements PlatformService { ... }
class IOSService implements PlatformService { ... }
class WebService implements PlatformService { ... }  // Easy to add
```

### Liskov Substitution Principle (LSP)

Any `PlatformService` implementation can be substituted:

```dart
void setupPlatform(PlatformService service, ProjectConfig config) {
  if (service.isPlatformAvailable()) {
    await service.setupFlavors(config);
  }
}

// All implementations work the same way
setupPlatform(AndroidService(), config);
setupPlatform(IOSService(), config);
setupPlatform(WebService(), config);
```

### Interface Segregation Principle (ISP)

Many specific interfaces rather than one general-purpose interface:

```dart
// ✅ Good - Specific interfaces
abstract class PlatformService { ... }
abstract class PostSetupService { ... }

// ❌ Bad - Fat interface
abstract class SetupService {
  Future<void> setupAndroid();
  Future<void> setupIOS();
  Future<void> runPodInstall();
  Future<void> flutterClean();
  // Forces all implementations to implement all methods
}
```

### Dependency Inversion Principle (DIP)

Depend on abstractions, not concretions:

```dart
// ✅ Good - Depends on abstraction
class FlavorSetupCommand {
  final PlatformService _androidService;
  final PlatformService _iosService;

  FlavorSetupCommand({
    PlatformService? androidService,
    PlatformService? iosService,
  }) : _androidService = androidService ?? AndroidService(),
       _iosService = iosService ?? IOSService();
}

// ❌ Bad - Depends on concrete classes
class FlavorSetupCommand {
  final AndroidService _androidService = AndroidService();
  final IOSService _iosService = IOSService();
}
```

## Layer Architecture

```
┌─────────────────────────────────────────┐
│         CLI Layer (Entry Point)         │
│  - User interaction                     │
│  - Command orchestration                │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│        Service Layer (Business Logic)   │
│  - Platform-specific implementations    │
│  - Service interfaces                   │
│  - Post-setup operations                │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│     Validation & Utils Layer            │
│  - Input validation                     │
│  - Project state validation             │
│  - Utility functions                    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Model Layer (Data)              │
│  - Pure data structures                 │
│  - No business logic                    │
└─────────────────────────────────────────┘
```

### Layer Details

#### 1. CLI Layer (`lib/src/cli/`)

**Responsibility**: User interaction and command orchestration

**Components**:

- `CLIInterface`: Handles prompts and user input
- `FlavorSetupCommand`: Orchestrates the setup process

**Rules**:

- No business logic
- Only coordinate between services
- Handle user input/output
- Error presentation

#### 2. Service Layer (`lib/src/services/`)

**Responsibility**: Business logic and platform-specific operations

**Components**:

- `PlatformService`: Interface for platform setup
- `AndroidService`: Android-specific implementation
- `IOSService`: iOS-specific implementation
- `DartService`: Dart file generation
- `VSCodeService`: IDE configuration
- `PostSetupService`: Post-setup operations

**Rules**:

- Implement platform-specific logic
- Return `SetupResult` objects
- No direct user interaction
- Stateless operations

#### 3. Validation & Utils Layer

**Responsibility**: Validation and reusable utilities

**Components**:

- `InputValidator`: User input validation
- `ProjectValidator`: Project state validation
- `StringUtils`: String manipulation
- `FileUtils`: File operations
- `ConsoleUtils`: Console output

**Rules**:

- Pure functions where possible
- No state management
- Reusable across services
- No platform-specific logic

#### 4. Model Layer (`lib/src/models/`)

**Responsibility**: Data structures

**Components**:

- `FlavorConfig`: Single flavor configuration
- `ProjectConfig`: Complete project configuration
- `SetupResult`: Operation result

**Rules**:

- Pure data classes
- No business logic
- Immutable where possible
- Value objects

## Design Patterns

### 1. Strategy Pattern

Used for platform-specific implementations:

```dart
abstract class PlatformService {
  Future<SetupResult> setupFlavors(ProjectConfig config);
}

class AndroidService implements PlatformService { ... }
class IOSService implements PlatformService { ... }
```

### 2. Builder Pattern

Used for configuration construction:

```dart
final config = ProjectConfig(
  appName: 'MyApp',
  appFileName: 'my_app',
  flavors: [
    FlavorConfig(name: 'dev', ...),
    FlavorConfig(name: 'prod', ...),
  ],
);
```

### 3. Template Method Pattern

Used in setup process:

```dart
class FlavorSetupCommand {
  Future<void> execute() async {
    final config = await _gatherInputs();      // Step 1
    _cli.displayConfigSummary(config);         // Step 2
    await _setupPlatforms(config);             // Step 3
    await _dartService.setupDartFiles(config); // Step 4
    await _vscodeService.createLaunchConfig(); // Step 5
    await _runPostSetup();                     // Step 6
    _cli.displayCompletion();                  // Step 7
  }
}
```

### 4. Factory Pattern

Used for validation results:

```dart
class ValidationResult {
  factory ValidationResult.valid(String value) => ...;
  factory ValidationResult.invalid(String error) => ...;
}
```

### 5. Facade Pattern

IOSService coordinates multiple iOS-specific services:

```dart
class IOSService implements PlatformService {
  final PodfileUpdater _podfileUpdater;
  final XcodeProjectUpdater _projectUpdater;
  final XcodeSchemeGenerator _schemeGenerator;
  final InfoPlistUpdater _plistUpdater;

  Future<SetupResult> setupFlavors(ProjectConfig config) async {
    await _plistUpdater.updateInfoPlist();
    await _podfileUpdater.updatePodfile();
    await _projectUpdater.updateXcodeProject(config);
    await _schemeGenerator.generateSchemes(config);
  }
}
```

## Data Flow

### User Input Flow

```
User Input
    ↓
CLIInterface (validation)
    ↓
InputValidator
    ↓
ProjectConfig (model)
    ↓
FlavorSetupCommand
    ↓
[PlatformServices]
    ↓
SetupResult
    ↓
CLIInterface (display)
    ↓
User Output
```

### Service Execution Flow

```
FlavorSetupCommand.execute()
    ↓
├─> _gatherInputs()
│   ├─> CLIInterface.promptAppName()
│   ├─> CLIInterface.promptBundleId()
│   ├─> CLIInterface.promptPackageName()
│   └─> CLIInterface.promptFlavors()
│
├─> _setupPlatforms()
│   ├─> AndroidService.setupFlavors()
│   └─> IOSService.setupFlavors()
│       ├─> PodfileUpdater.updatePodfile()
│       ├─> XcodeProjectUpdater.updateXcodeProject()
│       └─> XcodeSchemeGenerator.generateSchemes()
│
├─> DartService.setupDartFiles()
│   ├─> _splitAndCreateAppFile()
│   ├─> _createDartEntryFiles()
│   └─> _updateWidgetTest()
│
├─> VSCodeService.createLaunchConfig()
│
└─> _runPostSetup()
    ├─> PodInstallService.execute()
    ├─> FlutterCleanService.execute()
    └─> FlutterPubGetService.execute()
```

## Extension Points

### Adding a New Platform

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
    return SetupResult.success(message: 'Web configured');
  }
}
```

2. Add to `FlavorSetupCommand`:

```dart
class FlavorSetupCommand {
  final WebService _webService;

  FlavorSetupCommand({
    WebService? webService,
  }) : _webService = webService ?? WebService();

  Future<void> _setupPlatforms(ProjectConfig config) async {
    // ... existing platforms

    if (_webService.isPlatformAvailable()) {
      await _webService.setupFlavors(config);
    }
  }
}
```

### Adding New Validators

Create in `lib/src/validators/`:

```dart
class CustomValidator {
  static ValidationResult validateCustom(String? input) {
    // Validation logic
    return ValidationResult.valid(input);
  }
}
```

### Adding New Utilities

Create in `lib/src/utils/`:

```dart
class CustomUtils {
  CustomUtils._();

  static String customOperation(String input) {
    // Implementation
    return result;
  }
}
```

## Best Practices

### 1. Dependency Injection

Always allow dependencies to be injected:

```dart
class MyService {
  final Dependency _dependency;

  MyService({Dependency? dependency})
    : _dependency = dependency ?? DefaultDependency();
}
```

### 2. Error Handling

Use `SetupResult` for operation results:

```dart
Future<SetupResult> myOperation() async {
  try {
    // Operation
    return SetupResult.success(message: 'Done');
  } catch (e) {
    return SetupResult.failure(message: 'Error: $e');
  }
}
```

### 3. Logging

Use `ConsoleUtils` for consistent output:

```dart
ConsoleUtils.success('Operation completed');
ConsoleUtils.error('Something went wrong');
ConsoleUtils.warning('Be careful');
ConsoleUtils.info('FYI');
```

### 4. File Operations

Use `FileUtils` for file operations:

```dart
final content = await FileUtils.readFileIfExists('path/to/file');
FileUtils.ensureDirectoryExists('path/to/dir');
```

### 5. Validation

Always validate inputs:

```dart
final validation = InputValidator.validateAppName(input);
if (!validation.isValid) {
  return SetupResult.failure(message: validation.error!);
}
```

## Testing Strategy (Future)

```
Unit Tests
  ↓
├─> Models (data structures)
├─> Validators (validation logic)
├─> Utils (utility functions)
└─> Service logic (mocked dependencies)

Integration Tests
  ↓
├─> Service interactions
├─> CLI command flow
└─> End-to-end setup

E2E Tests
  ↓
└─> Full setup on test projects
```

## Performance Considerations

1. **File Operations**: Minimize file reads/writes
2. **Validation**: Validate early, fail fast
3. **Service Execution**: Parallel where possible
4. **Memory**: Stream large files if needed

## Security Considerations

1. **Input Validation**: Always validate user input
2. **File Paths**: Sanitize file paths
3. **Command Execution**: Validate before executing shell commands
4. **Error Messages**: Don't expose sensitive information

---

This architecture ensures:

- ✅ Maintainability
- ✅ Testability
- ✅ Extensibility
- ✅ Readability
- ✅ Scalability
