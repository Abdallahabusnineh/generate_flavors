import 'dart:io';
import '../../models/project_config.dart';
import '../../models/setup_result.dart';
import '../../utils/console_utils.dart';
import '../platform_service.dart';
import 'podfile_updater.dart';
import 'xcode_project_updater.dart';
import 'xcode_scheme_generator.dart';
import 'info_plist_updater.dart';

/// Service for iOS flavor setup
class IOSService implements PlatformService {
  final PodfileUpdater _podfileUpdater;
  final XcodeProjectUpdater _projectUpdater;
  final XcodeSchemeGenerator _schemeGenerator;
  final InfoPlistUpdater _plistUpdater;

  IOSService({
    PodfileUpdater? podfileUpdater,
    XcodeProjectUpdater? projectUpdater,
    XcodeSchemeGenerator? schemeGenerator,
    InfoPlistUpdater? plistUpdater,
  })  : _podfileUpdater = podfileUpdater ?? PodfileUpdater(),
        _projectUpdater = projectUpdater ?? XcodeProjectUpdater(),
        _schemeGenerator = schemeGenerator ?? XcodeSchemeGenerator(),
        _plistUpdater = plistUpdater ?? InfoPlistUpdater();

  @override
  String get platformName => 'iOS';

  @override
  bool isPlatformAvailable() {
    return Directory('ios').existsSync() &&
        File('ios/Runner.xcodeproj/project.pbxproj').existsSync();
  }

  @override
  Future<SetupResult> setupFlavors(ProjectConfig config) async {
    ConsoleUtils.ios('Configuring iOS flavors...');

    // Update Info.plist
    await _plistUpdater.updateInfoPlist();

    // Update Podfile (must be done before project updates)
    final podfileResult =
        await _podfileUpdater.updatePodfile(config.flavorNames);
    if (!podfileResult.success) {
      return podfileResult;
    }

    // Update Xcode project
    final projectResult = await _projectUpdater.updateXcodeProject(config);
    if (!projectResult.success) {
      return projectResult;
    }

    // Generate schemes
    final schemeResult = await _schemeGenerator.generateSchemes(config);
    if (!schemeResult.success) {
      return schemeResult;
    }

    ConsoleUtils.success('iOS flavors fully configured!');
    ConsoleUtils.info(
      '   Run: flutter run --flavor ${config.flavorNames.first} -t lib/main_${config.flavorNames.first}.dart',
    );

    return SetupResult.success(message: 'iOS flavors configured');
  }
}
