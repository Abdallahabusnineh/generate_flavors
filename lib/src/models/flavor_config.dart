/// Configuration model for a single flavor
class FlavorConfig {
  final String name;
  final String displayName;
  final String bundleId;
  final String packageName;

  FlavorConfig({
    required this.name,
    required this.displayName,
    required this.bundleId,
    required this.packageName,
  });

  /// Whether this is the production flavor
  bool get isProduction => name.toLowerCase() == 'prod';

  /// Get the bundle ID suffix (empty for prod)
  String get bundleIdSuffix => isProduction ? '' : '.$name';

  /// Get the full bundle ID with suffix
  String get fullBundleId => isProduction ? bundleId : '$bundleId.$name';

  /// Get the display name with flavor (e.g., "MyApp DEV")
  String get fullDisplayName =>
      isProduction ? displayName : '$displayName ${name.toUpperCase()}';

  @override
  String toString() => 'FlavorConfig($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlavorConfig &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
