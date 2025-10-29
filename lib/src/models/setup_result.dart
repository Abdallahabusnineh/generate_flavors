/// Result of a setup operation
class SetupResult {
  final bool success;
  final String message;
  final List<String> warnings;
  final dynamic data;

  SetupResult._({
    required this.success,
    required this.message,
    this.warnings = const [],
    this.data,
  });

  factory SetupResult.success({
    String message = 'Operation completed successfully',
    List<String> warnings = const [],
    dynamic data,
  }) {
    return SetupResult._(
      success: true,
      message: message,
      warnings: warnings,
      data: data,
    );
  }

  factory SetupResult.failure({
    required String message,
    List<String> warnings = const [],
  }) {
    return SetupResult._(
      success: false,
      message: message,
      warnings: warnings,
    );
  }

  @override
  String toString() =>
      'SetupResult(success: $success, message: $message, warnings: ${warnings.length})';
}
