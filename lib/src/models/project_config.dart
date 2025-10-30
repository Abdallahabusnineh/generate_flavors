import 'flavor_config.dart';

/// Configuration model for the entire project
class ProjectConfig {
  final String appName;
  final String appFileName;
  final String baseBundleId;
  final String androidPackageName;
  final List<FlavorConfig> flavors;
  final bool hasExistingFlavors;

  ProjectConfig({
    required this.appName,
    required this.appFileName,
    required this.baseBundleId,
    required this.androidPackageName,
    required this.flavors,
    this.hasExistingFlavors = false,
  });

  /// Get package name from pubspec.yaml
  String get packageName {
    return appFileName;
  }

  /// Get all flavor names
  List<String> get flavorNames => flavors.map((f) => f.name).toList();

  /// Check if a flavor exists in the configuration
  bool hasFlavor(String name) =>
      flavors.any((f) => f.name.toLowerCase() == name.toLowerCase());

  @override
  String toString() => 'ProjectConfig($appName, ${flavorNames.join(', ')})';
}
