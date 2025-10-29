/// Utility class for string transformations
class StringUtils {
  StringUtils._();

  /// Converts a string to snake_case
  static String toSnakeCase(String input) {
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

  /// Converts a string to Title Case
  static String toTitleCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  /// Generates a unique Xcode ID (24-character hex string)
  static String generateXcodeId(int counter) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueValue = (timestamp + counter).toRadixString(16).toUpperCase();
    final padding = '0' * (24 - uniqueValue.length);
    return '$padding$uniqueValue';
  }
}
