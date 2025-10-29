/// Flutter Flavor Setup - A tool for setting up flavors in Flutter projects
///
/// This library provides a comprehensive solution for managing multiple flavors
/// (environments) in your Flutter applications for both Android and iOS.
///
/// ## Features
/// - ✅ Automatic Android product flavor configuration
/// - ✅ iOS scheme and build configuration setup
/// - ✅ Dart entry point generation
/// - ✅ VSCode/Cursor launch configuration
/// - ✅ Support for existing flavor management
/// - ✅ Clean SOLID architecture
///
/// ## Usage
///
/// ### As a CLI tool:
/// ```bash
/// dart run flutter_flavor_setup
/// ```
///
/// ### Programmatic usage:
/// ```dart
/// import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';
///
/// Future<void> main() async {
///   final command = FlavorSetupCommand();
///   await command.execute();
/// }
/// ```
library;

// Models
export 'src/models/flavor_config.dart';
export 'src/models/project_config.dart';
export 'src/models/setup_result.dart';

// Services
export 'src/services/android_service.dart';
export 'src/services/dart_service.dart';
export 'src/services/ios/ios_service.dart';
export 'src/services/platform_service.dart';
export 'src/services/post_setup_service.dart';
export 'src/services/vscode_service.dart';

// Validators
export 'src/validators/input_validator.dart';
export 'src/validators/project_validator.dart';

// Utils
export 'src/utils/console_utils.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/string_utils.dart';

// CLI
export 'src/cli/cli_interface.dart';
export 'src/cli/flavor_setup_command.dart';
