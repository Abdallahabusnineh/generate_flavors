import 'dart:io';

/// Utility class for console output
class ConsoleUtils {
  ConsoleUtils._();

  // Console output methods
  static void success(String message) =>
      print(ConsoleUtils.boldGreen('✅ $message'));
  static void error(String message) => print(ConsoleUtils.red('❌ $message'));
  static void warning(String message) =>
      print(ConsoleUtils.yellow('⚠️  $message'));
  static void info(String message) => print(ConsoleUtils.blue('ℹ️  $message'));
  static void step(String message) => print('\n${ConsoleUtils.blue(message)}');

  // Emoji output for different platforms
  static void android(String message) =>
      print(ConsoleUtils.boldGreen('🤖 $message'));
  static void ios(String message) => print(ConsoleUtils.blue('🍎 $message'));
  static void dart(String message) => print(ConsoleUtils.blue('🎯 $message'));
  static void test(String message) => print(ConsoleUtils.yellow('🧪 $message'));
  static void config(String message) =>
      print(ConsoleUtils.blue('⚙️  $message'));
  static void file(String message) => print(ConsoleUtils.blue('📁 $message'));
  static void rocket(String message) =>
      print(ConsoleUtils.boldGreen('🚀 $message'));

  /// Prints a separator line
  static void separator() => print('\n${ConsoleUtils.blue('─' * 60)}\n');

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

  static String boldGreen(String text) => '\x1B[1;32m$text\x1B[0m';
  static String yellow(String text) => '\x1B[33m$text\x1B[0m';
  static String red(String text) => '\x1B[31m$text\x1B[0m';
  static String blue(String text) => '\x1B[34m$text\x1B[0m';
}
