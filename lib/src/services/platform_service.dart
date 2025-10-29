import '../models/project_config.dart';
import '../models/setup_result.dart';

/// Abstract interface for platform-specific setup
abstract class PlatformService {
  /// Sets up flavors for the platform
  Future<SetupResult> setupFlavors(ProjectConfig config);

  /// Checks if platform files exist
  bool isPlatformAvailable();

  /// Gets the platform name
  String get platformName;
}
