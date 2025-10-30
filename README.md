# Flutter Flavor Setup

A comprehensive, production-ready tool for setting up and managing flavors (environments) in Flutter projects. Built with SOLID principles for maintainability and extensibility.

## 🎯 Features

- ✅ **Android Configuration**: Automatic product flavor setup in `build.gradle`/`build.gradle.kts`
- ✅ **iOS Configuration**: Xcode scheme and build configuration generation
- ✅ **Dart Entry Points**: Automatic generation of flavor-specific main files
- ✅ **IDE Support**: VSCode/Cursor launch configuration generation
- ✅ **Existing Flavor Management**: Smart detection and merging of existing flavors
- ✅ **Clean Architecture**: Built following SOLID principles for easy maintenance
- ✅ **Type Safety**: Full Dart type safety with comprehensive error handling

## 📦 Installation

### As a development dependency

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_flavor_setup:
    git:
      url: https://github.com/Abdallahabusnineh/flutter_flavor_setup.git
```

Then run:

```bash
flutter pub get
```

### As a global tool

```bash
dart pub global activate flutter_flavor_setup
```

## 🚀 Usage

### CLI Usage

Run the setup wizard:

```bash
# If installed as dev dependency
dart run flutter_flavor_setup

# If installed globally
setup_flavors

# Or directly from bin
dart bin/setup_flavors.dart
```

The wizard will guide you through:

1. **App Name**: Enter your application name
2. **Bundle ID**: iOS bundle identifier (e.g., `com.example.myapp`)
3. **Package Name**: Android package name (e.g., `com.example.myapp`)
4. **Flavors**: Comma-separated list (e.g., `dev,qa,prod`)

### Example

```bash
$ dart run flutter_flavor_setup

Enter your app name: My Awesome App
Enter your iOS base bundle ID: com.example.myapp
Enter your Android package name: com.example.myapp
Enter flavors separated by commas: dev,qa,prod

🚀 Starting flavor setup for: dev, qa, prod
📱 App Name: My Awesome App
🍎 iOS Bundle ID: com.example.myapp
🤖 Android Package: com.example.myapp
📄 App File: lib/my_awesome_app.dart

✅ All done! Flavors setup complete 🎉
```

### Programmatic Usage

```dart
import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';

Future<void> main() async {
  // Create configuration
  final config = ProjectConfig(
    appName: 'MyApp',
    appFileName: 'my_app',
    baseBundleId: 'com.example.myapp',
    androidPackageName: 'com.example.myapp',
    flavors: [
      FlavorConfig(
        name: 'dev',
        displayName: 'MyApp',
        bundleId: 'com.example.myapp',
        packageName: 'com.example.myapp',
      ),
      FlavorConfig(
        name: 'prod',
        displayName: 'MyApp',
        bundleId: 'com.example.myapp',
        packageName: 'com.example.myapp',
      ),
    ],
  );

  // Setup platforms
  final androidService = AndroidService();
  await androidService.setupFlavors(config);

  final iosService = IOSService();
  await iosService.setupFlavors(config);

  // Setup Dart files
  final dartService = DartService();
  await dartService.setupDartFiles(config);
}
```

## 📁 Generated Structure

After running the setup, your project will have:

### Android (`android/app/build.gradle.kts`)

```kotlin
flavorDimensions += "default"
productFlavors {
    create("dev") {
        dimension = "default"
        applicationIdSuffix = ".dev"
        resValue("string", "app_name", "MyApp DEV")
    }
    create("prod") {
        dimension = "default"
        resValue("string", "app_name", "MyApp")
    }
}
```

### iOS (`ios/Runner.xcodeproj/`)

- `xcshareddata/xcschemes/dev.xcscheme`
- `xcshareddata/xcschemes/prod.xcscheme`
- Build configurations: `Debug-dev`, `Release-dev`, `Profile-dev`, etc.

### Dart Files

```
lib/
├── my_app.dart          # Main app widget
├── main_dev.dart        # Dev entry point
└── main_prod.dart       # Prod entry point
```

### VSCode Configuration (`.vscode/launch.json`)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "My App - DEV (Debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "args": ["--flavor", "dev"],
      "flutterMode": "debug"
    }
  ]
}
```

## 🏃 Running Flavors

### Command Line

```bash
# Run dev flavor
flutter run --flavor dev -t lib/main_dev.dart

# Run prod flavor in release mode
flutter run --flavor prod -t lib/main_prod.dart --release
```

### VSCode/Cursor

Use the Run and Debug panel (F5) and select the flavor configuration.

### Android Studio

Select the flavor from the "Build Variants" panel.

## 🏗️ Architecture

This package follows SOLID principles:

```
lib/
├── src/
│   ├── models/           # Data models (FlavorConfig, ProjectConfig)
│   ├── services/         # Business logic services
│   │   ├── android_service.dart
│   │   ├── ios/          # iOS-specific services
│   │   ├── dart_service.dart
│   │   └── vscode_service.dart
│   ├── validators/       # Input and project validation
│   ├── utils/           # Utility functions
│   └── cli/             # CLI interface
└── flutter_flavor_setup.dart  # Public API
```

### Key Principles

- **Single Responsibility**: Each service handles one specific platform/task
- **Open/Closed**: Easy to extend with new platforms without modifying existing code
- **Dependency Inversion**: Services depend on abstractions (interfaces)
- **Interface Segregation**: Specific interfaces for each service type

### Custom Validation

Add custom validators:

```dart
class CustomValidator {
  static ValidationResult validateCustomRule(String? input) {
    if (input == null || !input.startsWith('custom_')) {
      return ValidationResult.invalid('Must start with custom_');
    }
    return ValidationResult.valid(input);
  }
}
```

## 📝 Reserved Keywords

The following flavor names are reserved and cannot be used:

- `test` (use `testing`, `beta`, `staging` instead)
- `androidTest`
- `debug` (build type)
- `release` (build type)
- `profile` (build type)
- `main`

## 🐛 Troubleshooting

### Flavors already exist

The tool automatically detects existing flavors and offers options:

- Skip existing flavors and add only new ones
- Cancel the setup

### Pod install fails

Ensure you have CocoaPods installed:

```bash
sudo gem install cocoapods
```

### Build configuration errors

The tool creates flavor-specific build configurations (e.g., `Debug-dev`). Ensure your IDE recognizes these configurations by:

1. Closing and reopening the project
2. Running `flutter clean`
3. Invalidating caches (Android Studio)

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture
4. Write tests for new functionality
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Built with ❤️ for the Flutter community
- Inspired by best practices from various flavor management tools
- Architecture follows Clean Code and SOLID principles

## 📞 Support

- 📧 Email: [Abdallah Abusnineh](mailto:abusninehabdallah@gmail.com)
- 🐛 Issues: [GitHub Issues](https://github.com/AbdallahAbusnineh/flutter_flavor_setup/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/AbdallahAbusnineh/flutter_flavor_setup/discussions)
- ☕ Support Me: [![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-%2300AA00?style=for-the-badge&logo=buymeacoffee&logoColor=white)](https://buymeacoffee.com/abusninehaf)

Made with ❤️ by [Abdallah Abusnineh](https://github.com/AbdallahAbusnineh)
