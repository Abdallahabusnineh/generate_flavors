import 'dart:io';

/// Utility class for console output
class ConsoleUtils {
  ConsoleUtils._();

  // Console output methods
  static void success(String message) => print('✅ $message');
  static void error(String message) => print('❌ $message');
  static void warning(String message) => print('⚠️  $message');
  static void info(String message) => print('ℹ️  $message');
  static void step(String message) => print('\n$message');

  // Emoji output for different platforms
  static void android(String message) => print('🤖 $message');
  static void ios(String message) => print('🍎 $message');
  static void dart(String message) => print('🎯 $message');
  static void test(String message) => print('🧪 $message');
  static void config(String message) => print('⚙️  $message');
  static void file(String message) => print('📁 $message');
  static void rocket(String message) => print('🚀 $message');

  /// Prints a separator line
  static void separator() => print('\n${'─' * 60}\n');

  /// Prompts user for input
  static String? prompt(String message) {
    stdout.write(message);
    return stdin.readLineSync()?.trim();
  }

  /// Prompts user for yes/no confirmation
  static bool confirm(String message) {
    final response = prompt('$message (y/n): ')?.toLowerCase();
    return response == 'y' || response == 'yes';
  }

  /// Prints a list of items with bullets
  static void printList(List<String> items, {String prefix = '  •'}) {
    for (final item in items) {
      print('$prefix $item');
    }
  }
}
