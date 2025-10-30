import 'dart:io';

import '../../models/setup_result.dart';
import '../../utils/console_utils.dart';

/// Updates iOS Podfile for flavor support
class PodfileUpdater {
  Future<SetupResult> updatePodfile(List<String> flavors) async {
    ConsoleUtils.step('📦 Configuring iOS Podfile...');

    final podfile = File('ios/Podfile');
    if (!podfile.existsSync()) {
      ConsoleUtils.warning('Podfile not found');
      return SetupResult.failure(message: 'Podfile not found');
    }

    var content = await podfile.readAsString();

    // Add use_modular_headers! if not present
    if (!content.contains('use_modular_headers!')) {
      final targetPattern = RegExp(
        r"^\s*target\s+[\x27\x22]Runner[\x27\x22]\s+do\s*$",
        multiLine: true,
      );

      final match = targetPattern.firstMatch(content);
      if (match != null) {
        final insertPosition = match.end;
        content =
            '${content.substring(0, insertPosition)}\n  use_modular_headers!${content.substring(insertPosition)}';
        ConsoleUtils.success('Added use_modular_headers! to Podfile');
      }
    } else {
      ConsoleUtils.success('Podfile already contains use_modular_headers!');
    }

    await podfile.writeAsString(content);
    ConsoleUtils.success('Podfile configured successfully');
    ConsoleUtils.info(
      '   Note: Default configurations (Debug/Release/Profile) are kept for CocoaPods compatibility',
    );

    return SetupResult.success(message: 'Podfile updated');
  }


}
