import 'dart:convert';
import 'dart:io';

// Run with: dart setup_flavors.dart

Future<void> main() async {
  // Get app name
  stdout.write(
    'Enter your app name (must start with a letter and contain only letters and numbers and no spaces): (e.g. MyAwesomeApp): ',
  );
  String? appNameInput = stdin.readLineSync();
  appNameInput = appNameInput?.trim();
  if (appNameInput == null || appNameInput.trim().isEmpty) {
    print('❌ No app name entered. Exiting.');
    exit(0);
  } else if (!appNameInput.startsWith(RegExp(r'[a-zA-Z]'))) {
    print('❌ App name must start with a letter. Exiting.');
    exit(0);
  } else if (appNameInput.contains(RegExp(r'[^a-zA-Z0-9]'))) {
    print('❌ App name must contain only letters and numbers. Exiting.');
    exit(0);
  } else if (appNameInput.contains(RegExp(r'\s'))) {
    print('❌ App name must not contain spaces. Exiting.');
    exit(0);
  }
  final appName = appNameInput.trim();
  final appFileName = _toSnakeCase(appName);

  // Get flavors
  stdout.write('Enter flavors separated by commas (e.g. dev,qa,prod): ');
  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    print('❌ No flavors entered. Exiting.');
    exit(0);
  }

  final flavors =
      input.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();

  print('\n🚀 Starting flavor setup for: ${flavors.join(', ')}');
  print('📱 App Name: $appName');
  print('📄 App File: lib/$appFileName.dart\n');

  await _createEnvFiles(flavors);
  await _setupAndroid(flavors, appName);
  await _setupIOS(flavors, appName);
  await _deleteMainDart();
  await _splitAndCreateAppFile(appName, appFileName);
  await _createDartEntryFiles(flavors, appName, appFileName);
  await _updateWidgetTest(appName, appFileName);
  await _createVSCodeLaunchConfig(flavors, appName);

  print('\n✅ All done! Flavors setup complete 🎉');
  print('\nExample run commands:');
  for (final f in flavors) {
    print('flutter run --flavor $f -t lib/main_$f.dart');
  }
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .toLowerCase()
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _toTitleCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .split(' ')
      .map(
        (word) =>
            word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '',
      )
      .join(' ');
}

Future<void> _createEnvFiles(List<String> flavors) async {
  print('📁 Creating .env files...');
  for (final flavor in flavors) {
    final file = File('.env.$flavor');
    if (!file.existsSync()) {
      file.writeAsStringSync(
        'FLAVOR=$flavor\nAPI_URL=https://api.$flavor.example.com',
      );
      print('✅ Created ${file.path}');
    } else {
      print('⚠️ ${file.path} already exists, skipped');
    }
  }
}

Future<void> _setupAndroid(List<String> flavors, String appName) async {
  print('\n🤖 Configuring Android flavors...');

  final gradleFile = File('android/app/build.gradle');
  final gradleKtsFile = File('android/app/build.gradle.kts');

  final isKts = gradleKtsFile.existsSync();
  final targetFile = isKts ? gradleKtsFile : gradleFile;

  if (!targetFile.existsSync()) {
    print('❌ Cannot find ${targetFile.path}');
    return;
  }

  var content = await targetFile.readAsString();

  if (content.contains('productFlavors')) {
    print('⚠️ Android flavors already configured in ${targetFile.path}');
  } else {
    final flavorBlock =
        isKts
            ? '''
    flavorDimensions += "default"
    productFlavors {
${flavors.map((f) => '''
        create("$f") {
            dimension = "default"
            ${f != 'prod' ? 'applicationIdSuffix = ".$f"' : ''}
            resValue("string", "app_name", "$appName${f != 'prod' ? ' ${f.toUpperCase()}' : ''}")
        }''').join('\n')}
    }
'''
            : '''
    flavorDimensions "default"
    productFlavors {
${flavors.map((f) => '''
        $f {
            dimension "default"
            ${f != 'prod' ? 'applicationIdSuffix ".$f"' : ''}
            resValue "string", "app_name", "$appName${f != 'prod' ? ' ${f.toUpperCase()}' : ''}"
        }''').join('\n')}
    }
''';

    final newContent = content.replaceFirstMapped(
      RegExp(r'(defaultConfig\s*\{[^}]*\})', multiLine: true),
      (match) => '${match.group(0)}\n$flavorBlock',
    );

    await targetFile.writeAsString(newContent);
    print('✅ Updated ${targetFile.path} with flavors.');
  }

  // Update main AndroidManifest.xml to use @string/app_name
  final mainManifest = File('android/app/src/main/AndroidManifest.xml');
  if (mainManifest.existsSync()) {
    var manifestContent = await mainManifest.readAsString();

    // Replace android:label with @string/app_name
    if (!manifestContent.contains('android:label="@string/app_name"')) {
      manifestContent = manifestContent.replaceAllMapped(
        RegExp(r'android:label="[^"]*"'),
        (match) => 'android:label="@string/app_name"',
      );

      await mainManifest.writeAsString(manifestContent);
      print('✅ Updated AndroidManifest.xml to use @string/app_name');
    } else {
      print('⚠️ AndroidManifest.xml already uses @string/app_name');
    }
  }
}

Future<void> _setupIOS(List<String> flavors, String appName) async {
  print('\n🍎 Configuring iOS flavors...');

  final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
  schemesDir.createSync(recursive: true);

  // Delete the default Runner.xcscheme if it exists
  final defaultScheme = File('${schemesDir.path}/Runner.xcscheme');
  if (defaultScheme.existsSync()) {
    defaultScheme.deleteSync();
    print('✅ Deleted default Runner.xcscheme');
  }

  // Read and modify project.pbxproj
  final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!pbxprojFile.existsSync()) {
    print('❌ project.pbxproj not found');
    return;
  }

  var pbxContent = await pbxprojFile.readAsString();

  // Find Runner target ID
  String? runnerTargetId;
  final targetMatch = RegExp(
    r'([A-F0-9]{24}) \/\* Runner \*\/ = \{[^}]*isa = PBXNativeTarget',
  ).firstMatch(pbxContent);
  if (targetMatch != null) {
    runnerTargetId = targetMatch.group(1);
    print('✅ Found Runner target ID: $runnerTargetId');
  } else {
    runnerTargetId = '97C146ED1CF9000F007C117D';
    print('⚠️ Using fallback Runner target ID');
  }

  // Find existing configuration IDs
  final debugConfigMatch = RegExp(
    r'([A-F0-9]{24}) \/\* Debug \*\/ = \{',
  ).firstMatch(pbxContent);
  final releaseConfigMatch = RegExp(
    r'([A-F0-9]{24}) \/\* Release \*\/ = \{',
  ).firstMatch(pbxContent);
  final profileConfigMatch = RegExp(
    r'([A-F0-9]{24}) \/\* Profile \*\/ = \{',
  ).firstMatch(pbxContent);

  if (debugConfigMatch == null || releaseConfigMatch == null) {
    print('❌ Could not find Debug/Release configurations');
    return;
  }

  // Generate new configuration IDs and add them
  final configsToAdd = <String, Map<String, String>>{};

  for (final flavor in flavors) {
    configsToAdd['Debug-$flavor'] = {
      'id': _generateXcodeId(),
      'base': 'Debug',
      'baseId': debugConfigMatch.group(1)!,
      'xcconfig': 'Debug-$flavor.xcconfig',
    };
    configsToAdd['Release-$flavor'] = {
      'id': _generateXcodeId(),
      'base': 'Release',
      'baseId': releaseConfigMatch.group(1)!,
      'xcconfig': 'Release-$flavor.xcconfig',
    };
    if (profileConfigMatch != null) {
      configsToAdd['Profile-$flavor'] = {
        'id': _generateXcodeId(),
        'base': 'Profile',
        'baseId': profileConfigMatch.group(1)!,
        'xcconfig': 'Profile-$flavor.xcconfig',
      };
    }
  }

  // Add build configurations to XCConfigurationList
  pbxContent = _addBuildConfigurationsToPbxproj(pbxContent, configsToAdd);

  // Associate xcconfig files with configurations
  pbxContent = _associateXcconfigFiles(pbxContent, configsToAdd);

  await pbxprojFile.writeAsString(pbxContent);
  print('✅ Updated project.pbxproj with build configurations');

  for (final flavor in flavors) {
    // Create flavor-specific configuration in xcconfig files
    final debugConfigDir = Directory('ios/Flutter');
    debugConfigDir.createSync(recursive: true);

    final debugConfig = File('ios/Flutter/Debug-$flavor.xcconfig');
    if (!debugConfig.existsSync()) {
      debugConfig.writeAsStringSync('''
#include "Generated.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp${flavor != 'prod' ? '.$flavor' : ''}
PRODUCT_NAME = $appName${flavor != 'prod' ? ' ${flavor.toUpperCase()}' : ''}
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
''');
      print('✅ Created Debug-$flavor.xcconfig');
    }

    final releaseConfig = File('ios/Flutter/Release-$flavor.xcconfig');
    if (!releaseConfig.existsSync()) {
      releaseConfig.writeAsStringSync('''
#include "Generated.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp${flavor != 'prod' ? '.$flavor' : ''}
PRODUCT_NAME = $appName${flavor != 'prod' ? ' ${flavor.toUpperCase()}' : ''}
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
''');
      print('✅ Created Release-$flavor.xcconfig');
    }

    final profileConfig = File('ios/Flutter/Profile-$flavor.xcconfig');
    if (!profileConfig.existsSync()) {
      profileConfig.writeAsStringSync('''
#include "Generated.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.example.myapp${flavor != 'prod' ? '.$flavor' : ''}
PRODUCT_NAME = $appName${flavor != 'prod' ? ' ${flavor.toUpperCase()}' : ''}
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon
''');
      print('✅ Created Profile-$flavor.xcconfig');
    }

    // Create Xcode scheme with just the flavor name
    final scheme = File('${schemesDir.path}/$flavor.xcscheme');
    if (!scheme.existsSync()) {
      scheme.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
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
</Scheme>
''');
      print('✅ Created Xcode scheme: $flavor.xcscheme');
    } else {
      print('⚠️ Xcode scheme $flavor.xcscheme already exists, skipped');
    }
  }

  print('\n✅ iOS flavors fully configured!');
  print('   Run: flutter run --flavor dev -t lib/main_dev.dart');
}

String _generateXcodeId() {
  final random =
      DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
  final padding = '0' * (24 - random.length);
  return '$padding$random';
}

String _addBuildConfigurationsToPbxproj(
  String content,
  Map<String, Map<String, String>> configs,
) {
  // Find the XCBuildConfiguration section
  final buildConfigSectionMatch = RegExp(
    r'\/\* Begin XCBuildConfiguration section \*\/(.*?)\/\* End XCBuildConfiguration section \*\/',
    multiLine: true,
    dotAll: true,
  ).firstMatch(content);

  if (buildConfigSectionMatch == null) {
    print('⚠️ Could not find XCBuildConfiguration section');
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

    // Find a sample config to copy structure from
    final sampleConfigMatch = RegExp(
      r'([A-F0-9]{24}) \/\* ' +
          configData['base']! +
          r' \*\/ = \{[^}]*buildSettings = \{[^}]*\};[^}]*\};',
      multiLine: true,
      dotAll: true,
    ).firstMatch(buildConfigSection);

    if (sampleConfigMatch != null) {
      var newConfig = sampleConfigMatch.group(0)!;
      newConfig = newConfig.replaceFirst(
        RegExp(r'([A-F0-9]{24})'),
        configData['id']!,
      );
      newConfig = newConfig.replaceAll(
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

  // Now add references to XCConfigurationList
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

String _associateXcconfigFiles(
  String content,
  Map<String, Map<String, String>> configs,
) {
  for (final entry in configs.entries) {
    final configName = entry.key;
    final configData = entry.value;
    final xcconfigFile = configData['xcconfig']!;

    // Find the configuration block and add baseConfigurationReference
    final configBlockPattern = RegExp(
      '${configData['id']} \\/\\* $configName \\*\\/ = \\{[^}]*buildSettings = \\{',
      multiLine: true,
    );

    final configMatch = configBlockPattern.firstMatch(content);
    if (configMatch != null) {
      // Check if baseConfigurationReference already exists
      final endOfMatch = configMatch.end;
      final afterMatch = content.substring(endOfMatch, endOfMatch + 500);

      if (!afterMatch.contains('baseConfigurationReference')) {
        // Add baseConfigurationReference before buildSettings
        final insertPoint = configMatch.end - 'buildSettings = {'.length;
        final before = content.substring(0, insertPoint);
        final after = content.substring(insertPoint);

        content =
            '${before}baseConfigurationReference = ${_generateXcodeId()} /* $xcconfigFile */;\n\t\t\t$after';
      }
    }
  }

  return content;
}

Future<void> _splitAndCreateAppFile(String appName, String appFileName) async {
  print('\n📦 Extracting app widget from main.dart...');

  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    print('❌ lib/main.dart not found. Creating a new app file.');
    await _createNewAppFile(appName, appFileName);
    return;
  }

  var content = await mainFile.readAsString();

  // Find the MyApp class (handles extends, with, implements)
  final classPattern = RegExp(
    r'class\s+MyApp\s+extends\s+\w+(?:\s+with\s+[\w\s,]+)?(?:\s+implements\s+[\w\s,]+)?\s*\{',
    multiLine: true,
  );

  final classMatch = classPattern.firstMatch(content);

  if (classMatch == null) {
    print('⚠️ MyApp class not found in main.dart. Creating new app file.');
    await _createNewAppFile(appName, appFileName);
    return;
  }

  // Extract the full MyApp class by finding matching braces
  final classStart = classMatch.start;
  final classCode = _extractClass(content, classStart);

  if (classCode == null) {
    print('⚠️ Could not extract MyApp class properly. Creating new app file.');
    await _createNewAppFile(appName, appFileName);
    return;
  }

  // Rename MyApp to user's app name
  final renamedClassCode = classCode.replaceAllMapped(
    RegExp(r'\bMyApp\b'),
    (match) => appName,
  );

  // Create the new app file
  final appFile = File('lib/$appFileName.dart');
  appFile.writeAsStringSync('''
import 'package:flutter/material.dart';

$renamedClassCode
''');
  print('✅ Created lib/$appFileName.dart with $appName class');
}

String? _extractClass(String content, int startPos) {
  int braceCount = 0;
  int i = startPos;
  int classStart = startPos;

  // Find the opening brace
  while (i < content.length && content[i] != '{') {
    i++;
  }

  if (i >= content.length) return null;

  // Now count braces to find the end
  braceCount = 1;
  i++;

  while (i < content.length && braceCount > 0) {
    if (content[i] == '{') {
      braceCount++;
    } else if (content[i] == '}') {
      braceCount--;
    }
    i++;
  }

  if (braceCount != 0) return null;

  return content.substring(classStart, i);
}

Future<void> _createNewAppFile(String appName, String appFileName) async {
  final appFile = File('lib/$appFileName.dart');
  appFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class $appName extends StatelessWidget {
  const $appName({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ${appName}Page(title: '$appName'),
    );
  }
}

class ${appName}Page extends StatefulWidget {
  const ${appName}Page({super.key, required this.title});

  final String title;

  @override
  State<${appName}Page> createState() => _${appName}PageState();
}

class _${appName}PageState extends State<${appName}Page> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''');
  print('✅ Created lib/$appFileName.dart with $appName class');
}

Future<void> _createDartEntryFiles(
  List<String> flavors,
  String appName,
  String appFileName,
) async {
  print('\n📦 Creating Flutter entry files in lib/...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) libDir.createSync(recursive: true);

  for (final flavor in flavors) {
    final filename = 'lib/main_$flavor.dart';
    final file = File(filename);
    if (file.existsSync()) {
      print('⚠️ $filename already exists, skipped');
      continue;
    }

    file.writeAsStringSync('''
import 'package:flutter/material.dart';
import '$appFileName.dart';

/// Entry point for '$flavor' flavor
void main() {
  // TODO: Load flavor-specific configuration here
  // Example: await dotenv.load(fileName: ".env.$flavor");
  
  runApp(const $appName());
}
''');
    print('✅ Created $filename');
  }
}

Future<void> _updateWidgetTest(String appName, String appFileName) async {
  print('\n🧪 Updating test/widget_test.dart...');

  final testFile = File('test/widget_test.dart');
  if (!testFile.existsSync()) {
    print('⚠️ test/widget_test.dart not found. Skipping test update.');
    return;
  }

  var content = await testFile.readAsString();
  final packageName = _getPackageName();

  // Replace import from main.dart to the new app file
  content = content.replaceAllMapped(
    RegExp("import\\s+['\"]package:.+?/main\\.dart['\"];?"),
    (match) => "import 'package:$packageName/$appFileName.dart';",
  );

  // Replace MyApp references with the new app name
  content = content.replaceAllMapped(RegExp(r'\bMyApp\b'), (match) => appName);

  await testFile.writeAsString(content);
  print('✅ Updated test/widget_test.dart with correct imports and class names');
}

String _getPackageName() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return 'myapp'; // fallback
  }

  final content = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(
    r'^name:\s*(.+)$',
    multiLine: true,
  ).firstMatch(content);
  return nameMatch?.group(1)?.trim() ?? 'myapp';
}

Future<void> _createVSCodeLaunchConfig(
  List<String> flavors,
  String appName,
) async {
  print('\n🔧 Creating VS Code/Cursor launch configurations...');

  final vscodeDir = Directory('.vscode');
  vscodeDir.createSync(recursive: true);

  final launchFile = File('.vscode/launch.json');
  final displayAppName = _toTitleCase(appName);

  // Create configurations for each flavor in both debug and release modes
  final configurations = <Map<String, dynamic>>[];

  for (final flavor in flavors) {
    // Debug configuration
    configurations.add({
      'name': '$displayAppName - ${flavor.toUpperCase()} (Debug)',
      'request': 'launch',
      'type': 'dart',
      'program': 'lib/main_$flavor.dart',
      'args': ['--flavor', flavor],
      'flutterMode': 'debug',
    });

    // Release configuration
    configurations.add({
      'name': '$displayAppName - ${flavor.toUpperCase()} (Release)',
      'request': 'launch',
      'type': 'dart',
      'program': 'lib/main_$flavor.dart',
      'args': ['--flavor', flavor],
      'flutterMode': 'release',
    });
  }

  final launchConfig = {'version': '0.2.0', 'configurations': configurations};

  await launchFile.writeAsString(
    const JsonEncoder.withIndent('    ').convert(launchConfig),
  );

  print(
    '✅ Created .vscode/launch.json with ${configurations.length} configurations',
  );
  print('   📱 Available launch configurations:');
  for (final config in configurations) {
    print('   • ${config['name']}');
  }
}

Future<void> _deleteMainDart() async {
  print('\n🗑️ Deleting lib/main.dart...');

  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    print('⚠️ lib/main.dart not found. Nothing to delete.');
    return;
  }

  await mainFile.delete();
  print('✅ Deleted lib/main.dart');
}
