import 'dart:convert';
import 'dart:io';
import '../models/project_config.dart';
import '../models/setup_result.dart';
import '../utils/console_utils.dart';
import '../utils/string_utils.dart';

/// Service for managing VSCode/Cursor launch configurations
class VSCodeService {
  Future<SetupResult> createLaunchConfig(ProjectConfig config) async {
    ConsoleUtils.step('🔧 Updating VS Code/Cursor launch configurations...');

    final vscodeDir = Directory('.vscode');
    vscodeDir.createSync(recursive: true);

    final launchFile = File('.vscode/launch.json');
    final displayAppName = StringUtils.toTitleCase(config.appName);

    // Read existing configurations if file exists
    var existingConfigurations = <Map<String, dynamic>>[];
    if (launchFile.existsSync()) {
      try {
        final existingContent = await launchFile.readAsString();
        final existingJson =
            jsonDecode(existingContent) as Map<String, dynamic>;
        if (existingJson['configurations'] != null) {
          existingConfigurations = List<Map<String, dynamic>>.from(
            existingJson['configurations'],
          );
        }
      } catch (e) {
        ConsoleUtils.warning(
          'Could not parse existing launch.json, will recreate it',
        );
      }
    }

    // Get all existing flavors from main_*.dart files
    final allExistingFlavors = await _getAllExistingFlavors();

    if (allExistingFlavors.isEmpty) {
      ConsoleUtils.warning(
        'No flavors found (no main_*.dart files). Skipping launch.json update.',
      );
      return SetupResult.failure(message: 'No flavors found');
    }

    // Extract existing flavor configurations
    final existingFlavorConfigs = _extractFlavorConfigs(
      existingConfigurations,
      allExistingFlavors,
    );
    final nonFlavorConfigs = _extractNonFlavorConfigs(existingConfigurations);

    // Create configurations for all existing flavors
    final newConfigurations = _createFlavorConfigurations(
      allExistingFlavors.toList()..sort(),
      displayAppName,
      existingFlavorConfigs,
    );

    // Combine configurations
    final allConfigurations = [...nonFlavorConfigs, ...newConfigurations];

    final launchConfig = {
      'version': '0.2.0',
      'configurations': allConfigurations,
    };

    await launchFile.writeAsString(
      const JsonEncoder.withIndent('    ').convert(launchConfig),
    );

    // Count preserved vs new configs
    final preservedCount = existingFlavorConfigs.length;
    final newCount = newConfigurations.length - preservedCount;

    ConsoleUtils.success(
      'Updated .vscode/launch.json with ${newConfigurations.length} flavor configurations',
    );
    ConsoleUtils.info(
      '   📱 Flavors detected: ${allExistingFlavors.join(', ')}',
    );
    if (preservedCount > 0) {
      ConsoleUtils.info(
          '   🔄 Preserved $preservedCount existing configuration(s)');
    }
    if (newCount > 0) {
      ConsoleUtils.info('   ✨ Created $newCount new configuration(s)');
    }
    ConsoleUtils.info('   📱 Available launch configurations:');
    for (final config in newConfigurations) {
      ConsoleUtils.info('   • ${config['name']}');
    }

    return SetupResult.success(message: 'VSCode configuration updated');
  }

  Future<void> removeLaunchConfig() async {
    ConsoleUtils.step('🔧 Removing VS Code/Cursor launch configurations...');

    final launchFile = File('.vscode/launch.json');
    if (!launchFile.existsSync()) {
      ConsoleUtils.success('No VS Code/Cursor launch configurations found');
      return;
    }
    launchFile.deleteSync();
    ConsoleUtils.success('Removed VS Code/Cursor launch configurations');
  }

  Future<Set<String>> _getAllExistingFlavors() async {
    final allExistingFlavors = <String>{};
    final libDir = Directory('lib');
    if (libDir.existsSync()) {
      await for (final entity in libDir.list()) {
        if (entity is File &&
            entity.path.contains('main_') &&
            entity.path.contains('.dart')) {
          final filename = entity.path.split('/').last;
          final flavorMatch = RegExp(r'main_(\w+)\.dart').firstMatch(filename);
          if (flavorMatch != null) {
            allExistingFlavors.add(flavorMatch.group(1)!);
          }
        }
      }
    }
    return allExistingFlavors;
  }

  Map<String, Map<String, dynamic>> _extractFlavorConfigs(
    List<Map<String, dynamic>> existingConfigurations,
    Set<String> allExistingFlavors,
  ) {
    final existingFlavorConfigs = <String, Map<String, dynamic>>{};
    final flavorPattern =
        RegExp(r'^(.+?)\s+-\s+([A-Z]+)\s+\((Debug|Release)\)$');

    for (final config in existingConfigurations) {
      final name = config['name'] as String?;
      if (name == null) continue;

      final match = flavorPattern.firstMatch(name);
      if (match != null) {
        final flavor = match.group(2)!.toLowerCase();
        final mode = match.group(3)!;
        final key = '$flavor-$mode';

        // Only keep configs for flavors that still exist
        if (allExistingFlavors.contains(flavor)) {
          existingFlavorConfigs[key] = config;
        }
      }
    }

    return existingFlavorConfigs;
  }

  List<Map<String, dynamic>> _extractNonFlavorConfigs(
    List<Map<String, dynamic>> existingConfigurations,
  ) {
    final nonFlavorConfigs = <Map<String, dynamic>>[];
    final flavorPattern =
        RegExp(r'^(.+?)\s+-\s+([A-Z]+)\s+\((Debug|Release)\)$');

    for (final config in existingConfigurations) {
      final name = config['name'] as String?;
      if (name == null) {
        nonFlavorConfigs.add(config);
        continue;
      }

      final match = flavorPattern.firstMatch(name);
      if (match == null) {
        nonFlavorConfigs.add(config);
      }
    }

    return nonFlavorConfigs;
  }

  List<Map<String, dynamic>> _createFlavorConfigurations(
    List<String> flavors,
    String displayAppName,
    Map<String, Map<String, dynamic>> existingFlavorConfigs,
  ) {
    final newConfigurations = <Map<String, dynamic>>[];

    for (final flavor in flavors) {
      final debugKey = '$flavor-Debug';
      final releaseKey = '$flavor-Release';

      // Debug configuration
      if (existingFlavorConfigs.containsKey(debugKey)) {
        newConfigurations.add(existingFlavorConfigs[debugKey]!);
      } else {
        newConfigurations.add({
          'name': '$displayAppName - ${flavor.toUpperCase()} (Debug)',
          'request': 'launch',
          'type': 'dart',
          'program': 'lib/main_$flavor.dart',
          'args': ['--flavor', flavor],
          'flutterMode': 'debug',
        });
      }

      // Release configuration
      if (existingFlavorConfigs.containsKey(releaseKey)) {
        newConfigurations.add(existingFlavorConfigs[releaseKey]!);
      } else {
        newConfigurations.add({
          'name': '$displayAppName - ${flavor.toUpperCase()} (Release)',
          'request': 'launch',
          'type': 'dart',
          'program': 'lib/main_$flavor.dart',
          'args': ['--flavor', flavor],
          'flutterMode': 'release',
        });
      }
    }

    return newConfigurations;
  }
}
