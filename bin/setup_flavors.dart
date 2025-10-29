#!/usr/bin/env dart

import 'package:flutter_flavor_setup/flutter_flavor_setup.dart';

/// Entry point for the Flutter Flavor Setup CLI tool
///
/// Run with: dart run setup_flavors.dart
/// Or: dart bin/setup_flavors.dart
Future<void> main() async {
  final command = FlavorSetupCommand();
  await command.execute();
}
