import 'dart:io';
import '../../models/project_config.dart';
import '../../models/setup_result.dart';
import '../../utils/console_utils.dart';

/// Generates Xcode scheme files
class XcodeSchemeGenerator {
  Future<SetupResult> generateSchemes(ProjectConfig config) async {
    final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
    schemesDir.createSync(recursive: true);

    // Find Runner target ID
    final runnerTargetId = await _findRunnerTargetId();

    // Handle default Runner.xcscheme conversion
    final defaultScheme = File('${schemesDir.path}/Runner.xcscheme');
    final prodScheme = File('${schemesDir.path}/prod.xcscheme');

    if (defaultScheme.existsSync()) {
      if (config.hasFlavor('prod')) {
        await defaultScheme.rename('${schemesDir.path}/prod.xcscheme');
        ConsoleUtils.success('Converted Runner.xcscheme to prod.xcscheme');
      } else {
        defaultScheme.deleteSync();
        ConsoleUtils.success(
          'Deleted default Runner.xcscheme (prod flavor not requested)',
        );
      }
    }

    for (final flavor in config.flavors) {
      final scheme = File('${schemesDir.path}/${flavor.name}.xcscheme');

      // Update prod scheme if it was converted
      if (flavor.name == 'prod' && prodScheme.existsSync()) {
        ConsoleUtils.success('Using converted prod.xcscheme');
        _updateSchemeConfigurations(prodScheme, flavor.name);
        continue;
      }

      if (!scheme.existsSync()) {
        scheme.writeAsStringSync(_generateSchemeContent(
          flavor.name,
          runnerTargetId,
        ));
        ConsoleUtils.success('Created Xcode scheme: ${flavor.name}.xcscheme');
      } else {
        ConsoleUtils.warning(
          'Xcode scheme ${flavor.name}.xcscheme already exists, skipped',
        );
        _updateSchemeConfigurations(scheme, flavor.name);
      }
    }

    return SetupResult.success(message: 'Schemes generated');
  }

  Future<String> _findRunnerTargetId() async {
    final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
    if (!pbxprojFile.existsSync()) {
      return '97C146ED1CF9000F007C117D'; // fallback
    }

    final content = await pbxprojFile.readAsString();
    final targetMatch = RegExp(
      r'([A-F0-9]{24}) \/\* Runner \*\/ = \{[^}]*isa = PBXNativeTarget',
    ).firstMatch(content);

    return targetMatch?.group(1) ?? '97C146ED1CF9000F007C117D';
  }

  String _generateSchemeContent(String flavor, String runnerTargetId) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$runnerTargetId"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug-$flavor"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug-$flavor"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$runnerTargetId"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Profile-$flavor"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$runnerTargetId"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug-$flavor">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release-$flavor"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>''';
  }

  void _updateSchemeConfigurations(File schemeFile, String flavor) {
    if (!schemeFile.existsSync()) {
      ConsoleUtils.warning('Scheme file ${schemeFile.path} does not exist');
      return;
    }

    var content = schemeFile.readAsStringSync();
    var originalContent = content;

    // Update configurations to use flavor-specific ones
    content = content.replaceAllMapped(
      RegExp(r'buildConfiguration = "Debug"(?!-)'),
      (match) => 'buildConfiguration = "Debug-$flavor"',
    );

    content = content.replaceAllMapped(
      RegExp(r'buildConfiguration = "Profile"(?!-)'),
      (match) => 'buildConfiguration = "Profile-$flavor"',
    );

    content = content.replaceAllMapped(
      RegExp(r'buildConfiguration = "Release"(?!-)'),
      (match) => 'buildConfiguration = "Release-$flavor"',
    );

    if (content != originalContent) {
      schemeFile.writeAsStringSync(content);
      ConsoleUtils.success(
        'Updated ${schemeFile.path.split('/').last} to use $flavor-specific configurations',
      );
    } else {
      ConsoleUtils.success(
        '${schemeFile.path.split('/').last} already uses $flavor-specific configurations',
      );
    }
  }
}
