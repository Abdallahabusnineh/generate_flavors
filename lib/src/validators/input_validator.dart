import 'dart:io';

/// Validation result
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? value;

  ValidationResult._(this.isValid, this.error, this.value);

  factory ValidationResult.valid(String value) =>
      ValidationResult._(true, null, value);

  factory ValidationResult.invalid(String error) =>
      ValidationResult._(false, error, null);
}

/// Validator for user inputs
class InputValidator {
  InputValidator._();

  /// Reserved keywords that cannot be used as flavor names
  static const reservedKeywords = [
    'test',
    'androidTest',
    'debug',
    'release',
    'profile',
    'main',
  ];

  /// Validates app name
  static ValidationResult validateAppName(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult.invalid('No app name entered');
    }

    final trimmed = input.trim();

    if (!trimmed.startsWith(RegExp(r'[a-zA-Z]'))) {
      return ValidationResult.invalid('App name must start with a letter');
    }

    if (trimmed.contains(RegExp(r'[^a-zA-Z0-9 ]'))) {
      return ValidationResult.invalid(
        'App name can only contain letters, numbers and spaces',
      );
    }

    return ValidationResult.valid(trimmed);
  }

  /// Validates bundle ID or package name
  static ValidationResult validateBundleId(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult.invalid('No bundle ID entered');
    }

    final trimmed = input.trim();

    // Basic validation for bundle ID format (e.g., com.example.app)
    if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(trimmed)) {
      return ValidationResult.invalid(
        'Invalid bundle ID format. Use lowercase letters, numbers, and dots (e.g., com.example.app)',
      );
    }

    return ValidationResult.valid(trimmed);
  }

  /// Validates flavor names
  static ValidationResult validateFlavors(String? input) {
    if (input == null || input.trim().isEmpty) {
      return ValidationResult.invalid('No flavors entered');
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(input)) {
      return ValidationResult.invalid(
        'Flavor name must contain at least one letter',
      );
    }

    final flavors = input
        .split(',')
        .map((f) => f.trim().toLowerCase())
        .where((f) => f.isNotEmpty)
        .toList();

    if (flavors.isEmpty) {
      return ValidationResult.invalid('No valid flavors found');
    }

    // Check for reserved keywords
    final invalidFlavors =
        flavors.where((f) => reservedKeywords.contains(f)).toList();

    if (invalidFlavors.isNotEmpty) {
      return ValidationResult.invalid(
        'Reserved flavor names: ${invalidFlavors.join(', ')}. '
        'Suggestions: Use testing/beta/staging instead of test, '
        'debug/release/profile are build types',
      );
    }

    return ValidationResult.valid(flavors.join(','));
  }

  /// Validates package name from pubspec.yaml
  static String getPackageName() {
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
}
