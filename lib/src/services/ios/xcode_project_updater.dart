import 'dart:io';
import '../../models/flavor_config.dart';
import '../../models/project_config.dart';
import '../../models/setup_result.dart';
import '../../utils/console_utils.dart';
import '../../utils/string_utils.dart';

/// Updates Xcode project.pbxproj file
class XcodeProjectUpdater {
  int _idCounter = 0;

  Future<SetupResult> updateXcodeProject(ProjectConfig config) async {
    final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
    if (!pbxprojFile.existsSync()) {
      return SetupResult.failure(message: 'project.pbxproj not found');
    }

    var pbxContent = await pbxprojFile.readAsString();

    // Find Runner target ID and configuration IDs
    _findRunnerTargetId(pbxContent); // Logs the target ID for debugging
    final configIds = _findConfigurationIds(pbxContent);

    if (configIds == null) {
      return SetupResult.failure(
        message: 'Could not find Runner target configurations',
      );
    }

    ConsoleUtils.success(
        'Found Runner configurations: Debug, Release, Profile');

    // Ensure base xcconfig files exist
    _ensureBaseXcconfigFilesExist();

    // Remove any existing flavor configurations
    pbxContent = _removeFlavorConfigurations(pbxContent, config.flavorNames);

    // Generate new configuration IDs and data
    final configsToAdd = _generateConfigurationData(
      config.flavors,
      configIds,
    );

    // Add build configurations
    pbxContent = _addBuildConfigurationsToPbxproj(pbxContent, configsToAdd);

    // Add flavor-specific build settings
    pbxContent = _addFlavorSpecificBuildSettings(
      pbxContent,
      configsToAdd,
      config.flavors,
      config.appName,
      config.baseBundleId,
    );

    await pbxprojFile.writeAsString(pbxContent);
    ConsoleUtils.success('Updated project.pbxproj with build configurations');

    for (final flavor in config.flavors) {
      ConsoleUtils.success(
          'Configured build settings for ${flavor.name} flavor');
    }

    return SetupResult.success(message: 'Xcode project updated');
  }

  String _findRunnerTargetId(String content) {
    final targetMatch = RegExp(
      r'([A-F0-9]{24}) \/\* Runner \*\/ = \{[^}]*isa = PBXNativeTarget',
    ).firstMatch(content);

    if (targetMatch != null) {
      ConsoleUtils.success('Found Runner target ID: ${targetMatch.group(1)}');
      return targetMatch.group(1)!;
    }

    // Fallback
    ConsoleUtils.warning('Using fallback Runner target ID');
    return '97C146ED1CF9000F007C117D';
  }

  Map<String, String>? _findConfigurationIds(String content) {
    final runnerConfigListMatch = RegExp(
      r'buildConfigurationList = ([A-F0-9]{24}) \/\* Build configuration list for PBXNativeTarget "Runner" \*\/',
    ).firstMatch(content);

    if (runnerConfigListMatch == null) {
      ConsoleUtils.error('Could not find Runner target buildConfigurationList');
      return null;
    }

    final runnerConfigListId = runnerConfigListMatch.group(1)!;

    final configListPattern = RegExp(
      runnerConfigListId +
          r' \/\* Build configuration list for PBXNativeTarget "Runner" \*\/ = \{[^}]*buildConfigurations = \(\s*([A-F0-9]{24}) \/\* Debug \*\/,\s*([A-F0-9]{24}) \/\* Release \*\/,\s*([A-F0-9]{24}) \/\* Profile \*\/',
      multiLine: true,
      dotAll: true,
    );

    final configListMatch = configListPattern.firstMatch(content);
    if (configListMatch == null) {
      return null;
    }

    return {
      'debug': configListMatch.group(1)!,
      'release': configListMatch.group(2)!,
      'profile': configListMatch.group(3)!,
    };
  }

  void _ensureBaseXcconfigFilesExist() {
    final flutterDir = Directory('ios/Flutter');
    if (!flutterDir.existsSync()) {
      flutterDir.createSync(recursive: true);
    }

    final configs = ['Debug', 'Release', 'Profile'];
    for (final config in configs) {
      final configFile = File('ios/Flutter/$config.xcconfig');
      if (!configFile.existsSync()) {
        configFile.writeAsStringSync('#include "Generated.xcconfig"\n');
        ConsoleUtils.success('Created $config.xcconfig');
      }
    }
  }

  Map<String, Map<String, String>> _generateConfigurationData(
    List<FlavorConfig> flavors,
    Map<String, String> baseConfigIds,
  ) {
    final configsToAdd = <String, Map<String, String>>{};

    for (final flavor in flavors) {
      for (final type in ['Debug', 'Release', 'Profile']) {
        final configName = '$type-${flavor.name}';
        configsToAdd[configName] = {
          'id': StringUtils.generateXcodeId(_idCounter++),
          'base': type,
          'baseId': baseConfigIds[type.toLowerCase()]!,
          'xcconfig': '$type.xcconfig',
        };
      }
    }

    return configsToAdd;
  }

  String _removeFlavorConfigurations(String content, List<String> flavors) {
    for (final flavor in flavors) {
      for (final type in ['Debug', 'Release', 'Profile']) {
        final configName = '$type-$flavor';

        // Remove the full configuration block
        final configBlockPattern = RegExp(
          r'[A-F0-9]{24} \/\* ' +
              RegExp.escape(configName) +
              r' \*\/ = \{[^}]*(?:baseConfigurationReference[^;]*;)?[^}]*buildSettings = \{[^}]*\};[^}]*\};',
          multiLine: true,
          dotAll: true,
        );
        content = content.replaceAll(configBlockPattern, '');

        // Remove references from buildConfigurations lists
        final refPattern = RegExp(
          r'\s*[A-F0-9]{24} \/\* ' + RegExp.escape(configName) + r' \*\/,\s*',
          multiLine: true,
        );
        content = content.replaceAll(refPattern, '');
      }
    }

    return content;
  }

  String _addBuildConfigurationsToPbxproj(
    String content,
    Map<String, Map<String, String>> configs,
  ) {
    final buildConfigSectionMatch = RegExp(
      r'\/\* Begin XCBuildConfiguration section \*\/(.*?)\/\* End XCBuildConfiguration section \*\/',
      multiLine: true,
      dotAll: true,
    ).firstMatch(content);

    if (buildConfigSectionMatch == null) {
      ConsoleUtils.warning('Could not find XCBuildConfiguration section');
      return content;
    }

    var buildConfigSection = buildConfigSectionMatch.group(1)!;
    final sectionStart = buildConfigSectionMatch.start;
    final sectionEnd = buildConfigSectionMatch.end;

    // Add new configurations
    for (final entry in configs.entries) {
      final configName = entry.key;
      final configData = entry.value;

      if (content.contains('/* $configName */')) {
        continue; // Already exists
      }

      final baseConfigId = configData['baseId']!;
      final sampleConfigMatch = RegExp(
        baseConfigId +
            r' \/\* ' +
            configData['base']! +
            r' \*\/ = \{[^}]*buildSettings = \{[^}]*\};[^}]*\};',
        multiLine: true,
        dotAll: true,
      ).firstMatch(buildConfigSection);

      if (sampleConfigMatch != null) {
        var newConfig = sampleConfigMatch.group(0)!;
        newConfig = newConfig.replaceFirst(baseConfigId, configData['id']!);
        newConfig = newConfig.replaceFirst(
          '/* ${configData['base']} */',
          '/* $configName */',
        );
        newConfig = newConfig.replaceFirstMapped(
          RegExp(r'name = [^;]+;'),
          (match) => 'name = $configName;',
        );

        buildConfigSection += '\n$newConfig';
      }
    }

    content =
        '${content.substring(0, sectionStart)}/* Begin XCBuildConfiguration section */$buildConfigSection/* End XCBuildConfiguration section */${content.substring(sectionEnd)}';

    // Add references to XCConfigurationList
    final configListMatch = RegExp(
      r'(buildConfigurations = \(\s*(?:[A-F0-9]{24} \/\* [^*]+ \*\/,\s*)*)',
      multiLine: true,
    ).allMatches(content);

    for (final match in configListMatch) {
      var configList = match.group(1)!;
      for (final entry in configs.entries) {
        final configName = entry.key;
        final configData = entry.value;

        if (!configList.contains('/* $configName */')) {
          configList += '${configData['id']} /* $configName */,\n\t\t\t\t';
        }
      }
      content = content.replaceFirst(match.group(1)!, configList);
    }

    return content;
  }

  String _addFlavorSpecificBuildSettings(
    String content,
    Map<String, Map<String, String>> configs,
    List<FlavorConfig> flavors,
    String appName,
    String baseBundleId,
  ) {
    for (final flavor in flavors) {
      for (final type in ['Debug', 'Release', 'Profile']) {
        final configName = '$type-${flavor.name}';
        final configId = configs[configName]?['id'];

        if (configId == null) continue;

        final configPattern = RegExp(
          configId +
              r' /\* ' +
              RegExp.escape(configName) +
              r' \*/ = \{[^}]*isa = XCBuildConfiguration;[^}]*baseConfigurationReference[^;]*;[^}]*buildSettings = \{([^}]*)\};[^}]*\};',
          multiLine: true,
          dotAll: true,
        );

        final configMatch = configPattern.firstMatch(content);
        if (configMatch == null) continue;

        final fullMatch = configMatch.group(0)!;
        var buildSettings = configMatch.group(1)!;

        // Update build settings
        buildSettings = _updateBuildSetting(
          buildSettings,
          'PRODUCT_BUNDLE_IDENTIFIER',
          flavor.fullBundleId,
        );
        buildSettings = _updateBuildSetting(
          buildSettings,
          'PRODUCT_NAME',
          flavor.fullDisplayName,
        );
        buildSettings = _ensureBuildSetting(
          buildSettings,
          'SDKROOT',
          'iphoneos',
        );
        buildSettings = _ensureBuildSetting(
          buildSettings,
          'IPHONEOS_DEPLOYMENT_TARGET',
          '12.0',
        );
        buildSettings = _ensureBuildSetting(
          buildSettings,
          'TARGETED_DEVICE_FAMILY',
          '"1,2"',
        );

        final baseConfigRefMatch = RegExp(
          r'baseConfigurationReference = ([A-F0-9]{24}) /\* ([^*]+) \*/',
        ).firstMatch(fullMatch);

        final baseConfigRef = baseConfigRefMatch?.group(1) ?? '';
        final xcconfigComment =
            baseConfigRefMatch?.group(2) ?? configs[configName]?['xcconfig'];

        final newConfigBlock = '''$configId /* $configName */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = $baseConfigRef /* $xcconfigComment */;
			buildSettings = {$buildSettings
			};
			name = $configName;
		};''';

        content = content.replaceFirst(fullMatch, newConfigBlock);
      }
    }

    return content;
  }

  String _updateBuildSetting(
    String buildSettings,
    String key,
    String value,
  ) {
    if (buildSettings.contains(key)) {
      return buildSettings.replaceAllMapped(
        RegExp('$key = [^;]+;'),
        (match) => '$key = "$value";',
      );
    } else {
      return '$buildSettings\n\t\t\t\t$key = "$value";';
    }
  }

  String _ensureBuildSetting(
    String buildSettings,
    String key,
    String value,
  ) {
    if (!buildSettings.contains(key)) {
      return '$buildSettings\n\t\t\t\t$key = $value;';
    }
    return buildSettings;
  }
}
