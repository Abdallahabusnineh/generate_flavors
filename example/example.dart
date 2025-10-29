import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';

/// Example: Using Flutter Flavor Setup programmatically
Future<void> main() async {
  // Example 1: Using the CLI command (simplest approach)
  print('=== Example 1: CLI Command ===\n');
  final command = FlavorSetupCommand();
  await command.execute();

  // Example 2: Programmatic configuration
  print('\n=== Example 2: Programmatic Setup ===\n');
  await programmaticSetup();

  // Example 3: Custom service usage
  print('\n=== Example 3: Custom Service ===\n');
  await customServiceExample();
}

/// Example of programmatic setup
Future<void> programmaticSetup() async {
  // Create flavor configurations
  final flavors = [
    FlavorConfig(
      name: 'dev',
      displayName: 'MyApp',
      bundleId: 'com.example.myapp',
      packageName: 'com.example.myapp',
    ),
    FlavorConfig(
      name: 'staging',
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
  ];

  // Create project configuration
  final config = ProjectConfig(
    appName: 'MyApp',
    appFileName: 'my_app',
    baseBundleId: 'com.example.myapp',
    androidPackageName: 'com.example.myapp',
    flavors: flavors,
  );

  // Setup Android
  final androidService = AndroidService();
  if (androidService.isPlatformAvailable()) {
    ConsoleUtils.android('Setting up Android flavors...');
    final result = await androidService.setupFlavors(config);
    if (result.success) {
      ConsoleUtils.success(result.message);
    } else {
      ConsoleUtils.error(result.message);
    }
  }

  // Setup iOS
  final iosService = IOSService();
  if (iosService.isPlatformAvailable()) {
    ConsoleUtils.ios('Setting up iOS flavors...');
    final result = await iosService.setupFlavors(config);
    if (result.success) {
      ConsoleUtils.success(result.message);
    } else {
      ConsoleUtils.error(result.message);
    }
  }

  // Setup Dart files
  final dartService = DartService();
  ConsoleUtils.dart('Setting up Dart entry files...');
  final dartResult = await dartService.setupDartFiles(config);
  if (dartResult.success) {
    ConsoleUtils.success(dartResult.message);
  }

  // Setup VSCode
  final vscodeService = VSCodeService();
  ConsoleUtils.config('Setting up VSCode configuration...');
  final vscodeResult = await vscodeService.createLaunchConfig(config);
  if (vscodeResult.success) {
    ConsoleUtils.success(vscodeResult.message);
  }
}

/// Example of using individual services
Future<void> customServiceExample() async {
  // Example: Validate project state
  final hasExisting = await ProjectValidator.hasExistingFlavors();
  if (hasExisting) {
    ConsoleUtils.info('Project already has flavors configured');
  } else {
    ConsoleUtils.info('No existing flavors found');
  }

  // Example: Read existing configuration
  final existingBundleId = await ProjectValidator.readExistingBundleId();
  if (existingBundleId != null) {
    ConsoleUtils.info('Found bundle ID: $existingBundleId');
  }

  final existingPackage = await ProjectValidator.readExistingPackageName();
  if (existingPackage != null) {
    ConsoleUtils.info('Found package name: $existingPackage');
  }

  // Example: Validate input
  final appNameValidation = InputValidator.validateAppName('MyAwesomeApp');
  if (appNameValidation.isValid) {
    ConsoleUtils.success('App name is valid: ${appNameValidation.value}');
  } else {
    ConsoleUtils.error('Invalid app name: ${appNameValidation.error}');
  }

  // Example: String utilities
  final snakeCase = StringUtils.toSnakeCase('MyAwesomeApp');
  ConsoleUtils.info('Snake case: $snakeCase'); // my_awesome_app

  final titleCase = StringUtils.toTitleCase('myAwesomeApp');
  ConsoleUtils.info('Title case: $titleCase'); // My Awesome App
}
