import '../../generated/build_version.dart';
import 'app_config.dart';

/// Display and build metadata for the QuikDawa app version badge.
class AppVersionInfo {
  AppVersionInfo._();

  /// e.g. `v2026.D.2.06` (dev) or `v2026.P.2.06` (prod)
  static String get displayLabel {
    final year = DateTime.now().year;
    final env = AppConfig.isDevelopment ? 'D' : 'P';
    return 'v$year.$env.${BuildVersion.value}';
  }

  /// e.g. `quikdawa-dev-v2.06.apk` or `quikdawa-prod-v2.06.apk`
  static String get apkFileName {
    final flavor = AppConfig.isDevelopment ? 'dev' : 'prod';
    return 'quikdawa-$flavor-v${BuildVersion.value}.apk';
  }
}
