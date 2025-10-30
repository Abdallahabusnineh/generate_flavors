import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';

Future<void> main() async {
  final bundleId = await ProjectValidator.readExistingBundleId();
  if (bundleId == null) {
    print('No bundle ID found');
    return;
  }
  ConsoleUtils.success('Bundle ID: $bundleId');
}
