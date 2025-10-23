import 'dart:io';
// how to create flutter app with ? ... ?
// !!!  make dart setup_flavors.dart

Future<void> main() async {
  stdout.write('Enter flavors separated by commas (e.g. dev,qa,prod): ');
  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    print('❌ No flavors entered. Exiting.');
    exit(0);
  }

  final flavors =
      input.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();

  print('\n🚀 Starting flavor setup for: ${flavors.join(', ')}');

  await _createEnvFiles(flavors);
  await _setupAndroid(flavors);
  await _setupIOS(flavors);
  await _createDartEntryFiles(flavors);

  print('\n✅ All done! Flavors setup complete 🎉');
  print('\nExample run commands:');
  for (final f in flavors) {
    print('flutter run --flavor $f -t lib/main_$f.dart');
  }
}

Future<void> _createEnvFiles(List<String> flavors) async {
  print('\n📁 Creating .env files...');
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

Future<void> _setupAndroid(List<String> flavors) async {
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

  // Avoid multiple injections
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
            resValue("string", "app_name", "MyApp ${f.toUpperCase()}")
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
            resValue "string", "app_name", "MyApp ${f.toUpperCase()}"
        }''').join('\n')}
    }
''';

    // Try to inject after defaultConfig block (best-effort).
    final newContent = content.replaceFirstMapped(
      RegExp(r'(defaultConfig\s*\{[^}]*\})', multiLine: true),
      (match) => '${match.group(0)}\n$flavorBlock',
    );

    await targetFile.writeAsString(newContent);
    print('✅ Updated ${targetFile.path} with flavors.');
  }

  // Create AndroidManifest.xml for each flavor
  for (final flavor in flavors) {
    final dir = Directory('android/app/src/$flavor');
    dir.createSync(recursive: true);
    final manifest = File('${dir.path}/AndroidManifest.xml');
    if (!manifest.existsSync()) {
      manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp.$flavor">
    <application
        android:label="MyApp ${flavor.toUpperCase()}"
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

Future<void> _setupIOS(List<String> flavors) async {
  print('\n🍎 Configuring iOS flavors...');

  final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
  schemesDir.createSync(recursive: true);

  for (final flavor in flavors) {
    // Create Info.plist for each flavor
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
    <string>MyApp ${flavor.toUpperCase()}</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.myapp.$flavor</string>
</dict>
</plist>
''');
      print('✅ Created Info.plist for $flavor');
    } else {
      print('⚠️ Info.plist for $flavor already exists, skipped');
    }

    // Create Xcode scheme for each flavor (simple template)
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
    '\n⚠️ Note: This creates .xcscheme files and Info.plist files, but you may still need to set the corresponding build configurations in ios/Runner.xcodeproj/project.pbxproj (the script does not automatically patch the complex pbxproj). If you want, I can add a pbxproj editor to the script as well.',
  );
}

Future<void> _createDartEntryFiles(List<String> flavors) async {
  print('\n📦 Creating Flutter entry files in lib/ ...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) libDir.createSync(recursive: true);

  for (final flavor in flavors) {
    final filename = 'lib/main_$flavor.dart';
    final file = File(filename);
    if (file.existsSync()) {
      print('⚠️ $filename already exists, skipped');
      continue;
    }

    // Create a simple entry that calls mainCommon from main.dart.
    // Make sure your lib/main.dart exposes: void mainCommon(String flavor) { ... }
    file.writeAsStringSync('''
import 'main.dart' as app;

/// Entry point for '$flavor' flavor.
///
/// This expects that you implemented `void mainCommon(String flavor)`
/// inside lib/main.dart that sets up the app for the given flavor.
void main() => app.mainCommon('$flavor');
''');
    print('✅ Created $filename');
  }

  // Also create a small sample main.dart if not present (safe default)
  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    mainFile.writeAsStringSync('''
import 'package:flutter/material.dart';

/// Example mainCommon implementation used by generated entry points.
/// Replace with your real app bootstrap and environment loading.
void mainCommon(String flavor) {
  runApp(MyApp(flavor: flavor));
}

class MyApp extends StatelessWidget {
  final String flavor;
  const MyApp({required this.flavor, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp \$flavor',
      home: Scaffold(
        appBar: AppBar(title: Text('Flavor: \$flavor')),
        body: Center(child: Text('Running flavor: \$flavor')),
      ),
    );
  }
}
''');
    print(
      '⚠️ lib/main.dart not found — created a sample main.dart. Replace it with your real app bootstrap when ready.',
    );
  }
}
