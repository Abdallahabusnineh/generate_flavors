import '../models/flavor_config.dart';
import '../models/project_config.dart';
import '../utils/console_utils.dart';
import '../utils/string_utils.dart';
import '../validators/input_validator.dart';
import '../validators/project_validator.dart';

/// CLI interface for interacting with users
class CLIInterface {
  /// Prompts for app name
  Future<String?> promptAppName() async {
    final input = ConsoleUtils.prompt(
      'Enter your app name (must start with a letter and contain only letters and numbers and no spaces): (e.g. MyAwesomeApp): ',
    );

    final validation = InputValidator.validateAppName(input);
    if (!validation.isValid) {
      ConsoleUtils.error(validation.error!);
      return null;
    }

    return validation.value;
  }

  /// Prompts for bundle ID
  Future<String?> promptBundleId({String? existing}) async {
    if (existing != null) {
      ConsoleUtils.info('Found existing iOS Bundle ID: $existing');
      final choice = ConsoleUtils.prompt(
        'Do you want to:\n'
        '  1. Keep this Bundle ID\n'
        '  2. Enter a new Bundle ID\n'
        'Enter your choice (1/2): ',
      );

      if (choice == '1') {
        ConsoleUtils.success('Using existing Bundle ID: $existing');
        return existing;
      } else if (choice == '2') {
        return await _promptForNewBundleId();
      } else {
        ConsoleUtils.error('Invalid choice');
        return null;
      }
    } else {
      ConsoleUtils.info('No existing iOS Bundle ID found.');
      return await _promptForNewBundleId();
    }
  }

  Future<String?> _promptForNewBundleId() async {
    final input = ConsoleUtils.prompt(
      'Enter your iOS base bundle ID (e.g. com.example.myapp): ',
    );

    final validation = InputValidator.validateBundleId(input);
    if (!validation.isValid) {
      ConsoleUtils.error(validation.error!);
      return null;
    }

    return validation.value;
  }

  /// Prompts for Android package name
  Future<String?> promptPackageName({String? existing}) async {
    if (existing != null) {
      ConsoleUtils.info('Found existing Android package name: $existing');
      final choice = ConsoleUtils.prompt(
        'Do you want to:\n'
        '  1. Keep this package name\n'
        '  2. Enter a new package name\n'
        'Enter your choice (1/2): ',
      );

      if (choice == '1') {
        ConsoleUtils.success('Using existing package name: $existing');
        return existing;
      } else if (choice == '2') {
        return await _promptForNewPackageName();
      } else {
        ConsoleUtils.error('Invalid choice');
        return null;
      }
    } else {
      ConsoleUtils.info('No existing Android package name found.');
      return await _promptForNewPackageName();
    }
  }

  Future<String?> _promptForNewPackageName() async {
    final input = ConsoleUtils.prompt(
      'Enter your Android package name (e.g. com.example.myapp): ',
    );

    final validation = InputValidator.validateBundleId(input);
    if (!validation.isValid) {
      ConsoleUtils.error(validation.error!);
      return null;
    }

    return validation.value;
  }

  /// Prompts for flavors
  Future<List<String>?> promptFlavors() async {
    final input = ConsoleUtils.prompt(
      '\nEnter flavors separated by commas (e.g. dev,qa,prod): ',
    );

    final validation = InputValidator.validateFlavors(input);
    if (!validation.isValid) {
      ConsoleUtils.error(validation.error!);

      // Show suggestions for reserved keywords
      if (input != null &&
          input.contains(RegExp(r'test|debug|release|profile|main'))) {
        ConsoleUtils.info('💡 Suggestions:');
        ConsoleUtils.info(
            '   • Instead of "test", use: testing, beta, staging, demo');
        ConsoleUtils.info(
            '   • Instead of "debug/release", these are already build types');
      }
      return null;
    }

    return validation.value!.split(',').map((f) => f.trim()).toList();
  }

  /// Handles existing flavors prompt
  Future<List<String>?> handleExistingFlavors(
    List<String> requestedFlavors,
  ) async {
    final existingFlavors =
        await ProjectValidator.getExistingFlavors(requestedFlavors);

    if (existingFlavors.isEmpty) {
      ConsoleUtils.success(
          'No existing flavors found. Proceeding with setup...');
      return requestedFlavors;
    }

    ConsoleUtils.warning('The following flavor(s) already exist:');
    ConsoleUtils.printList(existingFlavors);

    final newFlavors =
        requestedFlavors.where((f) => !existingFlavors.contains(f)).toList();

    if (newFlavors.isNotEmpty) {
      ConsoleUtils.info('✨ New flavor(s) to be added:');
      ConsoleUtils.printList(newFlavors);
    }

    ConsoleUtils.info('');
    ConsoleUtils.info('Options:');
    ConsoleUtils.info(
      '1. Skip existing flavors (only add new ones: ${newFlavors.join(', ')})',
    );
    ConsoleUtils.info('2. Cancel setup');

    final response = ConsoleUtils.prompt('\nEnter your choice (1/2): ');

    if (response == '2') {
      ConsoleUtils.error('Setup cancelled by user.');
      return null;
    } else if (response == '1') {
      if (newFlavors.isEmpty) {
        ConsoleUtils.error('No new flavors to add. Exiting.');
        return null;
      }
      ConsoleUtils.success(
          'Will only setup new flavors: ${newFlavors.join(', ')}');
      return newFlavors;
    } else {
      ConsoleUtils.error('Invalid choice.');
      return null;
    }
  }

  /// Displays summary of configuration
  void displayConfigSummary(ProjectConfig config) {
    ConsoleUtils.separator();
    ConsoleUtils.rocket(
        'Starting flavor setup for: ${config.flavorNames.join(', ')}');
    ConsoleUtils.info('📱 App Name: ${config.appName}');
    ConsoleUtils.info('🍎 iOS Bundle ID: ${config.baseBundleId}');
    ConsoleUtils.info('🤖 Android Package: ${config.androidPackageName}');
    ConsoleUtils.info('📄 App File: lib/${config.appFileName}.dart');
    ConsoleUtils.separator();
  }

  /// Displays completion message
  void displayCompletion(List<String> flavors) {
    ConsoleUtils.separator();
    ConsoleUtils.success('All done! Flavors setup complete 🎉');
    ConsoleUtils.info('\nExample run commands:');
    for (final f in flavors) {
      ConsoleUtils.info('flutter run --flavor $f -t lib/main_$f.dart');
    }
    ConsoleUtils.separator();
  }

  /// Creates project config from gathered inputs
  ProjectConfig createProjectConfig({
    required String appName,
    required String baseBundleId,
    required String androidPackageName,
    required List<String> flavors,
    required bool hasExistingFlavors,
  }) {
    final appFileName = StringUtils.toSnakeCase(appName);
    final flavorConfigs = flavors.map((name) {
      return FlavorConfig(
        name: name,
        displayName: appName,
        bundleId: baseBundleId,
        packageName: androidPackageName,
      );
    }).toList();

    return ProjectConfig(
      appName: appName,
      appFileName: appFileName,
      baseBundleId: baseBundleId,
      androidPackageName: androidPackageName,
      flavors: flavorConfigs,
      hasExistingFlavors: hasExistingFlavors,
    );
  }
}
