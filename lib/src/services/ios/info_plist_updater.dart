import 'dart:io';
import '../../utils/console_utils.dart';

/// Updates Info.plist to use ${PRODUCT_NAME}
class InfoPlistUpdater {
  Future<void> updateInfoPlist() async {
    final infoPlistFile = File('ios/Runner/Info.plist');
    if (!infoPlistFile.existsSync()) {
      ConsoleUtils.warning('Info.plist not found, skipping update');
      return;
    }

    var content = await infoPlistFile.readAsString();

    // Check if CFBundleDisplayName already uses ${PRODUCT_NAME}
    if (content.contains('<string>\${PRODUCT_NAME}</string>')) {
      ConsoleUtils.success('Info.plist already uses \${PRODUCT_NAME}');
      return;
    }

    // Replace hardcoded app name with ${PRODUCT_NAME}
    content = content.replaceAllMapped(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>',
        multiLine: true,
      ),
      (match) =>
          '<key>CFBundleDisplayName</key>\n\t<string>\${PRODUCT_NAME}</string>',
    );

    await infoPlistFile.writeAsString(content);
    ConsoleUtils.success('Updated Info.plist to use \${PRODUCT_NAME}');
  }
}
