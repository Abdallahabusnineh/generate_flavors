import 'dart:io';
import '../models/setup_result.dart';
import '../utils/console_utils.dart';

/// Abstract interface for post-setup operations
abstract class PostSetupService {
  /// Executes the post-setup operation
  Future<SetupResult> execute();
}

/// Runs pod install for iOS
class PodInstallService implements PostSetupService {
  @override
  Future<SetupResult> execute() async {
    ConsoleUtils.step('📦 Running pod install...');

    final result = await Process.run(
      'pod',
      ['install'],
      workingDirectory: 'ios',
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      return SetupResult.failure(message: 'pod install failed');
    }

    ConsoleUtils.success('pod install completed');
    return SetupResult.success(message: 'Pod install completed');
  }
}

/// Runs flutter clean
class FlutterCleanService implements PostSetupService {
  @override
  Future<SetupResult> execute() async {
    ConsoleUtils.step('📦 Running flutter clean...');

    final result = await Process.run('flutter', ['clean']);

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      return SetupResult.failure(message: 'flutter clean failed');
    }

    ConsoleUtils.success('flutter clean completed');
    return SetupResult.success(message: 'Flutter clean completed');
  }
}

/// Runs flutter pub get
class FlutterPubGetService implements PostSetupService {
  @override
  Future<SetupResult> execute() async {
    ConsoleUtils.step('📦 Running flutter pub get...');

    final result = await Process.run('flutter', ['pub', 'get']);

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      return SetupResult.failure(message: 'flutter pub get failed');
    }

    ConsoleUtils.success('flutter pub get completed');
    return SetupResult.success(message: 'Flutter pub get completed');
  }
}
