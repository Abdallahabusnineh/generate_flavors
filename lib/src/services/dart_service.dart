import 'dart:io';

import '../models/project_config.dart';
import '../models/setup_result.dart';
import '../utils/console_utils.dart';

/// Service for generating Dart files
class DartService {
  /// Splits main.dart into app file and creates entry files
  Future<SetupResult> setupDartFiles(ProjectConfig config) async {
    // Split and create app file
    await _splitAndCreateAppFile(config.appName, config.appFileName);

    // Create entry files for each flavor
    await _createDartEntryFiles(
      config.flavorNames,
      config.appName.replaceAll(' ', ''),
      config.appFileName,
    );

    // Update widget test
    await _updateWidgetTest(
        config.appName.replaceAll(' ', ''), config.appFileName);

    // Delete main.dart
    await _deleteMainDart();

    return SetupResult.success(message: 'Dart files configured');
  }

  Future<void> _splitAndCreateAppFile(
    String appName,
    String appFileName,
  ) async {
    ConsoleUtils.step('📦 Extracting app code from main.dart...');
    final appNameWithoutSpaces = appName.replaceAll(' ', '');
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) {
      ConsoleUtils.error('lib/main.dart not found. Creating a new app file.');
      await _createNewAppFile(appNameWithoutSpaces, appFileName);
      return;
    }

    var content = await mainFile.readAsString();

    // Detect the actual app class name from runApp()
    final originalClassName = _detectAppClassName(content);

    if (originalClassName == null) {
      ConsoleUtils.warning(
        'Could not detect app class name from runApp(). Using default.',
      );
      final appContent = _removeMainFunction(content);
      final appFile = File('lib/$appFileName.dart');
      appFile.writeAsStringSync(appContent);
      ConsoleUtils.success(
        'Created lib/$appFileName.dart preserving original code',
      );
      return;
    }

    ConsoleUtils.info('Found app class: $originalClassName');

    // Remove the main() function and keep everything else
    final appContent = _removeMainFunction(content);

    // Rename the detected class to user's app name
    final renamedContent = appContent.replaceAllMapped(
      RegExp('\\b$originalClassName\\b'),
      (match) => appNameWithoutSpaces,
    );

    // Create the new app file
    final appFile = File('lib/$appFileName.dart');
    appFile.writeAsStringSync(renamedContent);
    ConsoleUtils.success(
      'Created lib/$appFileName.dart with $appNameWithoutSpaces class (renamed from $originalClassName)',
    );
  }

  String? _detectAppClassName(String content) {
    // Look for runApp(const ClassName()) or runApp(ClassName())
    final runAppPattern = RegExp(
      r'runApp\s*\(\s*(?:const\s+)?([A-Z][a-zA-Z0-9_]*)\s*\(',
      multiLine: true,
    );

    final match = runAppPattern.firstMatch(content);
    if (match != null) {
      return match.group(1);
    }

    // Also try to match: runApp(const ClassName.someConstructor())
    final runAppNamedPattern = RegExp(
      r'runApp\s*\(\s*(?:const\s+)?([A-Z][a-zA-Z0-9_]*)\.[\w]+\(',
      multiLine: true,
    );

    final namedMatch = runAppNamedPattern.firstMatch(content);
    if (namedMatch != null) {
      return namedMatch.group(1);
    }

    return null;
  }

  String _removeMainFunction(String content) {
    // Find "void main" or "Future<void> main"
    final mainPattern = RegExp(
      r'(Future<void>|void)\s+main\s*\(',
      multiLine: true,
    );

    final mainMatch = mainPattern.firstMatch(content);
    if (mainMatch == null) {
      return content.trim();
    }

    // Find the opening brace of main()
    var pos = content.indexOf('{', mainMatch.start);
    if (pos == -1) {
      return content.trim();
    }

    final mainStart = mainMatch.start;
    var braceCount = 1;
    pos++;

    // Count braces to find the end of main()
    while (pos < content.length && braceCount > 0) {
      if (content[pos] == '{') {
        braceCount++;
      } else if (content[pos] == '}') {
        braceCount--;
      }
      pos++;
    }

    if (braceCount != 0) {
      return content.trim();
    }

    // Remove the main function
    final beforeMain = content.substring(0, mainStart);
    final afterMain = content.substring(pos);
    return (beforeMain + afterMain).trim();
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
    ConsoleUtils.success('Created lib/$appFileName.dart with $appName class');
  }

  Future<void> _createDartEntryFiles(
    List<String> flavors,
    String appName,
    String appFileName,
  ) async {
    ConsoleUtils.step('📦 Creating Flutter entry files in lib/...');

    final libDir = Directory('lib');
    if (!libDir.existsSync()) libDir.createSync(recursive: true);

    for (final flavor in flavors) {
      final filename = 'lib/main_$flavor.dart';
      final file = File(filename);
      if (file.existsSync()) {
        ConsoleUtils.warning('$filename already exists, skipped');
        continue;
      }

      file.writeAsStringSync('''
import 'package:flutter/material.dart';
import '$appFileName.dart';

/// Entry point for '$flavor' flavor
void main() {
  print('main $appName $flavor');
  runApp(const $appName());
}
''');
      ConsoleUtils.success('Created $filename');
    }
  }

  Future<void> _updateWidgetTest(String appName, String appFileName) async {
    ConsoleUtils.step('🧪 Updating test/widget_test.dart...');

    final testFile = File('test/widget_test.dart');
    if (!testFile.existsSync()) {
      ConsoleUtils.warning(
        'test/widget_test.dart not found. Skipping test update.',
      );
      return;
    }

    var content = await testFile.readAsString();
    final packageName = _getPackageName();

    // Detect the original class name from the test file
    String? originalClassName = _detectClassNameFromTest(content);

    // If we couldn't detect from test, try detecting from main.dart
    if (originalClassName == null) {
      final mainFile = File('lib/main.dart');
      if (mainFile.existsSync()) {
        final mainContent = await mainFile.readAsString();
        originalClassName = _detectAppClassName(mainContent) ?? 'MyApp';
      } else {
        originalClassName = 'MyApp';
      }
    }

    ConsoleUtils.info('Detected original class: $originalClassName');

    // Replace import from main.dart to the new app file
    content = content.replaceAllMapped(
      RegExp("import\\s+['\"]package:.+?/main\\.dart['\"];?"),
      (match) => "import 'package:$packageName/$appFileName.dart';",
    );

    // Replace the detected class name with the new app name
    content = content.replaceAllMapped(
      RegExp('\\b$originalClassName\\b'),
      (match) => appName,
    );

    await testFile.writeAsString(content);
    ConsoleUtils.success(
      'Updated test/widget_test.dart: $originalClassName → $appName',
    );
  }

  String? _detectClassNameFromTest(String content) {
    // Pattern 1: pumpWidget(const? ClassName())
    final pumpWidgetPattern = RegExp(
      r'pumpWidget\s*\(\s*(?:const\s+)?([A-Z][a-zA-Z0-9_]*)\s*\(',
      multiLine: true,
    );
    final pumpMatch = pumpWidgetPattern.firstMatch(content);
    if (pumpMatch != null) {
      return pumpMatch.group(1);
    }

    // Pattern 2: find.byType(ClassName)
    final byTypePattern = RegExp(
      r'\.byType\s*\(\s*([A-Z][a-zA-Z0-9_]*)\s*\)',
      multiLine: true,
    );
    final byTypeMatch = byTypePattern.firstMatch(content);
    if (byTypeMatch != null) {
      return byTypeMatch.group(1);
    }

    return null;
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
    ConsoleUtils.step('🗑️  Deleting lib/main.dart...');
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) {
      ConsoleUtils.warning('lib/main.dart not found. Nothing to delete.');
      return;
    }
    await mainFile.delete();
    ConsoleUtils.success('Deleted lib/main.dart');
  }
}
