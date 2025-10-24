import 'dart:convert';
import 'dart:io';

// Run with: dart setup_flavors.dart

Future<void> main() async {
  // Get app name
  stdout.write(
    'Enter your app name (must start with a letter and contain only letters and numbers and no spaces): (e.g. MyAwesomeApp):',
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
  final displayAppName = _toTitleCase(appName);

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
            manifestPlaceholders["appName"] = "$displayAppName${f != 'prod' ? ' ${f.toUpperCase()}' : ''}"
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
            manifestPlaceholders appName: "$displayAppName${f != 'prod' ? ' ${f.toUpperCase()}' : ''}"
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

  // Update main AndroidManifest.xml to use placeholders
  final mainManifest = File('android/app/src/main/AndroidManifest.xml');
  if (mainManifest.existsSync()) {
    var manifestContent = await mainManifest.readAsString();

    // Check if placeholders are already configured
    if (!manifestContent.contains('android:label="@string/app_name"')) {
      // Update the application label to use the placeholder
      manifestContent = manifestContent.replaceFirstMapped(
        RegExp(r'android:label="[^"]*"'),
        (match) => 'android:label="@string/app_name"',
      );

      // If no label found, add it to the application tag
      if (!manifestContent.contains('android:label=')) {
        manifestContent = manifestContent.replaceFirstMapped(
          RegExp(r'<application([^>]*)>'),
          (match) =>
              '<application${match.group(1)} android:label="@string/app_name">',
        );
      }

      await mainManifest.writeAsString(manifestContent);
      print('✅ Updated main AndroidManifest.xml to use app_name placeholder');
    } else {
      print('⚠️ Main AndroidManifest.xml already uses app_name placeholder');
    }
  } else {
    print('⚠️ Main AndroidManifest.xml not found');
  }
}

Future<void> _setupIOS(List<String> flavors, String appName) async {
  print('\n🍎 Configuring iOS flavors...');

  final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
  schemesDir.createSync(recursive: true);
  final displayAppName = _toTitleCase(appName);

  // Update main Info.plist to use placeholders
  final mainPlist = File('ios/Runner/Info.plist');
  if (mainPlist.existsSync()) {
    var plistContent = await mainPlist.readAsString();

    // Check if placeholders are already configured
    if (!plistContent.contains('CFBundleDisplayName')) {
      // Add CFBundleDisplayName placeholder
      plistContent = plistContent.replaceFirstMapped(
        RegExp(r'<dict>'),
        (match) => '''<dict>
    <key>CFBundleDisplayName</key>
    <string>\$(APP_DISPLAY_NAME)</string>''',
      );
      await mainPlist.writeAsString(plistContent);
      print('✅ Updated main Info.plist to use APP_DISPLAY_NAME placeholder');
    } else {
      print('⚠️ Main Info.plist already uses APP_DISPLAY_NAME placeholder');
    }
  } else {
    print('⚠️ Main Info.plist not found');
  }

  for (final flavor in flavors) {
    final scheme = File('${schemesDir.path}/Runner-$flavor.xcscheme');
    if (!scheme.existsSync()) {
      final appDisplayName =
          '$displayAppName${flavor != 'prod' ? ' ${flavor.toUpperCase()}' : ''}';
      scheme.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion="1430"
   version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="13B07F861A680F5B00A75B9A" BuildableName="Runner.app" BlueprintName="Runner" ReferencedContainer="container:Runner.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="$flavor" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
   <LaunchAction buildConfiguration="$flavor" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <EnvironmentVariables>
         <EnvironmentVariable key="APP_DISPLAY_NAME" value="$appDisplayName" isEnabled="YES"/>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction buildConfiguration="$flavor" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
   <AnalyzeAction buildConfiguration="$flavor"/>
   <ArchiveAction buildConfiguration="$flavor" revealArchiveInOrganizer="YES"/>
</Scheme>
''');
      print('✅ Created Xcode scheme for $flavor');
    } else {
      print('⚠️ Xcode scheme for $flavor already exists, skipped');
    }
  }

  print(
    '\n⚠️ Note: You may need to manually configure build configurations in Xcode (ios/Runner.xcodeproj)',
  );
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

  // Find all imports at the beginning (not currently used)
  // final importMatches = RegExp(r"^import\s+[^;]+;$", multiLine: true).allMatches(content);
  // final imports = importMatches.map((m) => m.group(0)!).join('\n');

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
            Text(
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
