import 'dart:io';

// Run with: dart setup_flavors.dart

Future<void> main() async {
  // Get app name
  stdout.write('Enter your app name (e.g. MyAwesomeApp): ');
  final appNameInput = stdin.readLineSync();
  if (appNameInput == null || appNameInput.trim().isEmpty) {
    print('❌ No app name entered. Exiting.');
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
  await _splitAndCreateAppFile(appName, appFileName);
  await _createDartEntryFiles(flavors, appName, appFileName);
  await _updateWidgetTest(appName, appFileName);
  await _deleteMainDart();

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
            applicationIdSuffix = ".$f"
            resValue("string", "app_name", "$appName ${f.toUpperCase()}")
        }''').join('\n')}
    }
'''
            : '''
    flavorDimensions "default"
    productFlavors {
${flavors.map((f) => '''
        $f {
            dimension "default"
            applicationIdSuffix ".$f"
            resValue "string", "app_name", "$appName ${f.toUpperCase()}"
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

  for (final flavor in flavors) {
    final dir = Directory('android/app/src/$flavor');
    dir.createSync(recursive: true);
    final manifest = File('${dir.path}/AndroidManifest.xml');
    if (!manifest.existsSync()) {
      manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp.$flavor">
    <application
        android:label="$appName ${flavor.toUpperCase()}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
      print('✅ Created AndroidManifest for $flavor');
    } else {
      print('⚠️ AndroidManifest for $flavor already exists, skipped');
    }
  }
}

Future<void> _setupIOS(List<String> flavors, String appName) async {
  print('\n🍎 Configuring iOS flavors...');

  final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
  schemesDir.createSync(recursive: true);

  for (final flavor in flavors) {
    final plistDir = Directory('ios/Runner/$flavor');
    plistDir.createSync(recursive: true);
    final plist = File('${plistDir.path}/Info.plist');
    if (!plist.existsSync()) {
      plist.writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>$appName ${flavor.toUpperCase()}</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.myapp.$flavor</string>
</dict>
</plist>
''');
      print('✅ Created Info.plist for $flavor');
    } else {
      print('⚠️ Info.plist for $flavor already exists, skipped');
    }

    final scheme = File('${schemesDir.path}/Runner-$flavor.xcscheme');
    if (!scheme.existsSync()) {
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
   <LaunchAction buildConfiguration="$flavor" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"/>
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
      home: const MyHomePage(title: '$appName Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
