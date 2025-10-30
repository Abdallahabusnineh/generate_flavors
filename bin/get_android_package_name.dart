import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';

Future<void> main() async {
  final packageName = await ProjectValidator.readExistingPackageName();
  if (packageName == null) {
    ConsoleUtils.error('No package name found');
    return;
  }
  ConsoleUtils.success('Package name: $packageName');
}
