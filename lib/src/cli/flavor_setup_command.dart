import '../models/project_config.dart';
import '../services/android_service.dart';
import '../services/dart_service.dart';
import '../services/ios/ios_service.dart';
import '../services/post_setup_service.dart';
import '../services/vscode_service.dart';
import '../utils/console_utils.dart';
import '../validators/project_validator.dart';
import 'cli_interface.dart';

/// Main command for setting up flavors
class FlavorSetupCommand {
  final CLIInterface _cli;
  final AndroidService _androidService;
  final IOSService _iosService;
  final DartService _dartService;
  final VSCodeService _vscodeService;

  FlavorSetupCommand({
    CLIInterface? cli,
    AndroidService? androidService,
    IOSService? iosService,
    DartService? dartService,
    VSCodeService? vscodeService,
  })  : _cli = cli ?? CLIInterface(),
        _androidService = androidService ?? AndroidService(),
        _iosService = iosService ?? IOSService(),
        _dartService = dartService ?? DartService(),
        _vscodeService = vscodeService ?? VSCodeService();

  /// Executes the flavor setup command
  Future<void> execute() async {
    try {
      // Step 1: Gather inputs
      final config = await _gatherInputs();
      if (config == null) {
        return; // User cancelled or invalid input
      }

      // Step 2: Display summary
      _cli.displayConfigSummary(config);

      // Step 3: Setup platforms
      await _setupPlatforms(config);

      // Step 4: Setup Dart files
      await _dartService.setupDartFiles(config);

      // Step 5: Setup VSCode
      await _vscodeService.createLaunchConfig(config);

      // Step 6: Post-setup tasks
      await _runPostSetup();

      // Step 7: Display completion
      _cli.displayCompletion(config.flavorNames);
    } catch (e, stackTrace) {
      ConsoleUtils.error('An error occurred: $e');
      ConsoleUtils.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ProjectConfig?> _gatherInputs() async {
    // Get app name
    final appName = await _cli.promptAppName();
    if (appName == null) return null;

    // Check if flavors already exist
    final hasExistingFlavors = await ProjectValidator.hasExistingFlavors();

    // Get bundle ID
    final existingBundleId = await ProjectValidator.readExistingBundleId();
    String? baseBundleId;

    if (existingBundleId != null && hasExistingFlavors) {
      // Lock the bundle ID if flavors already exist
      baseBundleId = existingBundleId;
      ConsoleUtils.info(
          '🔒 Bundle ID is locked (flavors already exist). Using: $baseBundleId');
    } else {
      baseBundleId = await _cli.promptBundleId(existing: existingBundleId);
      if (baseBundleId == null) return null;
    }

    // Get Android package name
    final existingPackageName =
        await ProjectValidator.readExistingPackageName();
    String? androidPackageName;

    if (existingPackageName != null && hasExistingFlavors) {
      // Lock the package name if flavors already exist
      androidPackageName = existingPackageName;
      ConsoleUtils.info(
        '🔒 Package name is locked (flavors already exist). Using: $androidPackageName',
      );
    } else {
      androidPackageName =
          await _cli.promptPackageName(existing: existingPackageName);
      if (androidPackageName == null) return null;
    }

    // Get flavors
    final flavors = await _cli.promptFlavors();
    if (flavors == null) return null;

    // Handle existing flavors
    final finalFlavors = await _cli.handleExistingFlavors(flavors);
    if (finalFlavors == null) return null;

    // Remove VSCode launch config if no existing flavors
    if (!hasExistingFlavors) {
      await _vscodeService.removeLaunchConfig();
    }

    return _cli.createProjectConfig(
      appName: appName,
      baseBundleId: baseBundleId,
      androidPackageName: androidPackageName,
      flavors: finalFlavors,
      hasExistingFlavors: hasExistingFlavors,
    );
  }

  Future<void> _setupPlatforms(ProjectConfig config) async {
    // Setup Android
    if (_androidService.isPlatformAvailable()) {
      final result = await _androidService.setupFlavors(config);
      if (!result.success) {
        ConsoleUtils.warning('Android setup failed: ${result.message}');
      }
    } else {
      ConsoleUtils.warning('Android platform not available, skipping...');
    }

    // Setup iOS
    if (_iosService.isPlatformAvailable()) {
      final result = await _iosService.setupFlavors(config);
      if (!result.success) {
        ConsoleUtils.warning('iOS setup failed: ${result.message}');
      }
    } else {
      ConsoleUtils.warning('iOS platform not available, skipping...');
    }
  }

  Future<void> _runPostSetup() async {
    // Run pod install
    final podInstall = PodInstallService();
    final podResult = await podInstall.execute();
    if (!podResult.success) {
      ConsoleUtils.warning('Pod install failed: ${podResult.message}');
    }

    // Run flutter clean
    final flutterClean = FlutterCleanService();
    final cleanResult = await flutterClean.execute();
    if (!cleanResult.success) {
      ConsoleUtils.warning('Flutter clean failed: ${cleanResult.message}');
    }

    // Run flutter pub get
    final flutterPubGet = FlutterPubGetService();
    final pubGetResult = await flutterPubGet.execute();
    if (!pubGetResult.success) {
      ConsoleUtils.warning('Flutter pub get failed: ${pubGetResult.message}');
    }
  }
}
