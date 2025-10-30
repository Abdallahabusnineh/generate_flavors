import 'dart:io';

import '../../models/setup_result.dart';
import '../../utils/console_utils.dart';

/// Installs iOS Podfile for flavor support
class PodfileInstaller {
  Future<SetupResult> createPodfile() async {
    ConsoleUtils.step('📦 Creating Podfile file...');
    final podfile = File('ios/Podfile');
    if (!podfile.existsSync()) {
      await Process.run('pod', ['init'], workingDirectory: 'ios');
      ConsoleUtils.success(
          'Podfile file created successfully, Going to update it...');
      return SetupResult.success(message: 'Podfile file created successfully');
    }
    ConsoleUtils.warning('Podfile file already exists, Going to update it...');
    return SetupResult.failure(message: 'Podfile file already exists');
  }
}
