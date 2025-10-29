import 'dart:io';

/// Utility class for file operations
class FileUtils {
  FileUtils._();

  /// Reads a file if it exists, returns null otherwise
  static Future<String?> readFileIfExists(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    return await file.readAsString();
  }

  /// Creates a directory if it doesn't exist
  static void ensureDirectoryExists(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Deletes a file if it exists
  static Future<bool> deleteFileIfExists(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Checks if a file exists
  static bool fileExists(String path) => File(path).existsSync();

  /// Checks if a directory exists
  static bool directoryExists(String path) => Directory(path).existsSync();

  /// Lists files in a directory matching a pattern
  static Future<List<String>> listFilesMatching(
    String directoryPath,
    bool Function(String) matcher,
  ) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return [];

    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && matcher(entity.path)) {
        files.add(entity.path);
      }
    }
    return files;
  }
}
