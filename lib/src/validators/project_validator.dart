import 'dart:io';

/// Validates project state and existing configurations
class ProjectValidator {
  ProjectValidator._();

  /// Checks if any flavors already exist in the project
  static Future<bool> hasExistingFlavors() async {
    // Check Android flavors
    if (await _hasAndroidFlavors()) return true;

    // Check iOS schemes
    if (await _hasIOSFlavors()) return true;

    // Check for main_*.dart files
    if (await _hasDartFlavors()) return true;

    return false;
  }

  /// Checks if Android has product flavors configured
  static Future<bool> _hasAndroidFlavors() async {
    final gradleFile = File('android/app/build.gradle');
    final gradleKtsFile = File('android/app/build.gradle.kts');
    final androidFile = gradleKtsFile.existsSync() ? gradleKtsFile : gradleFile;

    if (androidFile.existsSync()) {
      final androidContent = await androidFile.readAsString();
      if (androidContent.contains('productFlavors')) {
        return true;
      }
    }
    return false;
  }

  /// Checks if iOS has custom schemes
  static Future<bool> _hasIOSFlavors() async {
    final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
    if (schemesDir.existsSync()) {
      final schemes = await schemesDir.list().toList();
      for (final scheme in schemes) {
        if (scheme is File && scheme.path.endsWith('.xcscheme')) {
          final schemeName = scheme.path.split('/').last;
          if (schemeName != 'Runner.xcscheme') {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Checks if Dart has flavor entry files
  static Future<bool> _hasDartFlavors() async {
    final libDir = Directory('lib');
    if (libDir.existsSync()) {
      await for (final entity in libDir.list()) {
        if (entity is File &&
            entity.path.contains('main_') &&
            entity.path.endsWith('.dart')) {
          return true;
        }
      }
    }
    return false;
  }

  /// Reads existing iOS Bundle ID from project.pbxproj
  static Future<String?> readExistingBundleId() async {
    final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
    if (!pbxprojFile.existsSync()) return null;

    final content = await pbxprojFile.readAsString();

    final bundleIdMatch = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
    ).firstMatch(content);

    if (bundleIdMatch != null) {
      var bundleId = bundleIdMatch.group(1)!.trim();
      bundleId = bundleId.replaceAll('"', '');

      if (bundleId.contains('\$')) return null;

      // Remove flavor suffix if present
      final suffixMatch = RegExp(
        r'^(.+)\.(dev|qa|prod|staging)$',
      ).firstMatch(bundleId);
      if (suffixMatch != null) {
        return suffixMatch.group(1);
      }

      return bundleId;
    }

    return null;
  }

  /// Reads existing Android package name from build.gradle
  static Future<String?> readExistingPackageName() async {
    final gradleFile = File('android/app/build.gradle');
    final gradleKtsFile = File('android/app/build.gradle.kts');

    final isKts = gradleKtsFile.existsSync();
    final targetFile = isKts ? gradleKtsFile : gradleFile;

    if (!targetFile.existsSync()) return null;

    final content = await targetFile.readAsString();

    final applicationIdPattern = isKts
        ? RegExp(r'applicationId\s*=\s*"([^"]+)"')
        : RegExp(r'applicationId\s+"([^"]+)"');

    final match = applicationIdPattern.firstMatch(content);
    if (match != null) {
      var packageName = match.group(1)!.trim();

      // Remove flavor suffix if present
      final suffixMatch = RegExp(
        r'^(.+)\.(dev|qa|prod|staging)$',
      ).firstMatch(packageName);
      if (suffixMatch != null) {
        return suffixMatch.group(1);
      }

      return packageName;
    }

    // Fallback: try namespace
    final namespacePattern = isKts
        ? RegExp(r'namespace\s*=\s*"([^"]+)"')
        : RegExp(r'namespace\s+"([^"]+)"');

    final namespaceMatch = namespacePattern.firstMatch(content);
    if (namespaceMatch != null) {
      return namespaceMatch.group(1)!.trim();
    }

    return null;
  }

  /// Checks which flavors from the list already exist
  static Future<List<String>> getExistingFlavors(List<String> flavors) async {
    final existingFlavors = <String>[];

    // Check Android
    final gradleFile = File('android/app/build.gradle');
    final gradleKtsFile = File('android/app/build.gradle.kts');
    final androidFile = gradleKtsFile.existsSync() ? gradleKtsFile : gradleFile;

    if (androidFile.existsSync()) {
      final androidContent = await androidFile.readAsString();
      for (final flavor in flavors) {
        if (androidContent.contains('create("$flavor")') ||
            androidContent.contains('$flavor {')) {
          if (!existingFlavors.contains(flavor)) {
            existingFlavors.add(flavor);
          }
        }
      }
    }

    // Check iOS schemes
    final schemesDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
    if (schemesDir.existsSync()) {
      for (final flavor in flavors) {
        final schemeFile = File('${schemesDir.path}/$flavor.xcscheme');
        if (schemeFile.existsSync() && !existingFlavors.contains(flavor)) {
          existingFlavors.add(flavor);
        }
      }
    }

    // Check Dart files
    for (final flavor in flavors) {
      final mainFile = File('lib/main_$flavor.dart');
      if (mainFile.existsSync() && !existingFlavors.contains(flavor)) {
        existingFlavors.add(flavor);
      }
    }

    return existingFlavors;
  }
}
