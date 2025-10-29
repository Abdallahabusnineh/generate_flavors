import 'dart:io';
import '../models/flavor_config.dart';
import '../models/project_config.dart';
import '../models/setup_result.dart';
import '../utils/console_utils.dart';
import 'platform_service.dart';

/// Service for Android flavor setup
class AndroidService implements PlatformService {
  @override
  String get platformName => 'Android';

  @override
  bool isPlatformAvailable() {
    return File('android/app/build.gradle').existsSync() ||
        File('android/app/build.gradle.kts').existsSync();
  }

  @override
  Future<SetupResult> setupFlavors(ProjectConfig config) async {
    ConsoleUtils.android('Configuring Android flavors...');

    final gradleFile = File('android/app/build.gradle');
    final gradleKtsFile = File('android/app/build.gradle.kts');

    final isKts = gradleKtsFile.existsSync();
    final targetFile = isKts ? gradleKtsFile : gradleFile;

    if (!targetFile.existsSync()) {
      return SetupResult.failure(
        message: 'Cannot find ${targetFile.path}',
      );
    }

    var content = await targetFile.readAsString();

    // Update applicationId
    content = _updateApplicationId(content, config.androidPackageName, isKts);

    // Update or create product flavors
    if (content.contains('productFlavors')) {
      content = await _addToExistingFlavors(
        content,
        config.flavors,
        config.appName,
        isKts,
      );
    } else {
      content = await _createFlavorBlock(
        content,
        config.flavors,
        config.appName,
        isKts,
      );
    }

    await targetFile.writeAsString(content);
    ConsoleUtils.success('Updated ${targetFile.path} with flavors');

    // Update AndroidManifest.xml
    await _updateManifest();

    return SetupResult.success(message: 'Android flavors configured');
  }

  String _updateApplicationId(
    String content,
    String packageName,
    bool isKts,
  ) {
    if (content.contains('applicationId')) {
      final applicationIdPattern = isKts
          ? RegExp(r'applicationId\s*=\s*"[^"]*"')
          : RegExp(r'applicationId\s+"[^"]*"');

      if (applicationIdPattern.hasMatch(content)) {
        content = content.replaceAll(
          applicationIdPattern,
          isKts
              ? 'applicationId = "$packageName"'
              : 'applicationId "$packageName"',
        );
        ConsoleUtils.success('Replaced applicationId with: $packageName');
      }
    }
    return content;
  }

  Future<String> _addToExistingFlavors(
    String content,
    List<FlavorConfig> flavors,
    String appName,
    bool isKts,
  ) async {
    ConsoleUtils.warning(
        'Android flavors already configured. Adding new flavors...');

    final productFlavorsStart = content.indexOf('productFlavors');
    if (productFlavorsStart == -1) {
      return content;
    }

    var pos = content.indexOf('{', productFlavorsStart);
    if (pos == -1) return content;

    final blockStart = pos;
    var braceCount = 1;
    pos++;

    while (pos < content.length && braceCount > 0) {
      if (content[pos] == '{') {
        braceCount++;
      } else if (content[pos] == '}') {
        braceCount--;
      }
      pos++;
    }

    if (braceCount != 0) {
      ConsoleUtils.warning('Malformed productFlavors block');
      return content;
    }

    final blockEnd = pos;
    var existingFlavorsBlock = content.substring(blockStart + 1, blockEnd - 1);

    final newFlavors = flavors.where((f) {
      final flavorExists = isKts
          ? existingFlavorsBlock.contains('create("${f.name}")')
          : existingFlavorsBlock.contains('${f.name} {');

      if (flavorExists) {
        ConsoleUtils.warning('Flavor "${f.name}" already exists, skipping');
      }
      return !flavorExists;
    }).toList();

    if (newFlavors.isEmpty) {
      ConsoleUtils.success('No new flavors to add');
      return content;
    }

    final newFlavorDefinitions = _generateFlavorDefinitions(
      newFlavors,
      appName,
      isKts,
    );

    final updatedFlavorsBlock =
        '${existingFlavorsBlock.trimRight()}\n$newFlavorDefinitions\n    ';

    final beforeBlock = content.substring(0, productFlavorsStart);
    final afterBlock = content.substring(blockEnd);
    content = '${beforeBlock}productFlavors {$updatedFlavorsBlock}$afterBlock';

    ConsoleUtils.success(
        'Added new flavors: ${newFlavors.map((f) => f.name).join(', ')}');

    return content;
  }

  Future<String> _createFlavorBlock(
    String content,
    List<FlavorConfig> flavors,
    String appName,
    bool isKts,
  ) async {
    final flavorDefinitions = _generateFlavorDefinitions(
      flavors,
      appName,
      isKts,
    );

    final flavorBlock = isKts
        ? '''
    flavorDimensions += "default"
    productFlavors {
$flavorDefinitions
    }
'''
        : '''
    flavorDimensions "default"
    productFlavors {
$flavorDefinitions
    }
''';

    // Find defaultConfig block to insert flavors after it
    final defaultConfigStart = content.indexOf('defaultConfig');
    if (defaultConfigStart == -1) {
      ConsoleUtils.error('Could not find defaultConfig block');
      return content;
    }

    var pos = content.indexOf('{', defaultConfigStart);
    if (pos == -1) return content;

    var braceCount = 1;
    pos++;

    while (pos < content.length && braceCount > 0) {
      if (content[pos] == '{') {
        braceCount++;
      } else if (content[pos] == '}') {
        braceCount--;
      }
      pos++;
    }

    if (braceCount != 0) {
      ConsoleUtils.error('Malformed defaultConfig block');
      return content;
    }

    final insertPosition = pos;
    final beforeInsert = content.substring(0, insertPosition);
    final afterInsert = content.substring(insertPosition);
    return '$beforeInsert\n$flavorBlock$afterInsert';
  }

  String _generateFlavorDefinitions(
    List<FlavorConfig> flavors,
    String appName,
    bool isKts,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < flavors.length; i++) {
      final f = flavors[i];
      if (isKts) {
        buffer.write('''
        create("${f.name}") {
            dimension = "default"''');
        if (!f.isProduction) {
          buffer.write('\n            applicationIdSuffix = ".${f.name}"');
        }
        buffer.write('''

            resValue("string", "app_name", "${f.fullDisplayName}")
        }''');
      } else {
        buffer.write('''
        ${f.name} {
            dimension "default"''');
        if (!f.isProduction) {
          buffer.write('\n            applicationIdSuffix ".${f.name}"');
        }
        buffer.write('''

            resValue "string", "app_name", "${f.fullDisplayName}"
        }''');
      }
      if (i < flavors.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  Future<void> _updateManifest() async {
    final mainManifest = File('android/app/src/main/AndroidManifest.xml');
    if (mainManifest.existsSync()) {
      var manifestContent = await mainManifest.readAsString();

      if (!manifestContent.contains('android:label="@string/app_name"')) {
        manifestContent = manifestContent.replaceAllMapped(
          RegExp(r'android:label="[^"]*"'),
          (match) => 'android:label="@string/app_name"',
        );

        await mainManifest.writeAsString(manifestContent);
        ConsoleUtils.success(
            'Updated AndroidManifest.xml to use @string/app_name');
      } else {
        ConsoleUtils.warning(
            'AndroidManifest.xml already uses @string/app_name');
      }
    }
  }
}
