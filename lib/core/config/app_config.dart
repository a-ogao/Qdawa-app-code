/// Application configuration constants
/// Contains all API URLs and base paths for the QuikDawa application
class AppConfig {
  // Base domain — dev: https://dev.quikdawa.com | prod: https://prod.quikdawa.com
  static const String baseDomain = 'https://dev.quikdawa.com';

  /// `true` when pointing at the development/testing server.
  static bool get isDevelopment => baseDomain.contains('dev.');

  /// `true` when pointing at the production server.
  static bool get isProduction => baseDomain.contains('prod.');

  // Base API URL
  static const String baseApiUrl = '$baseDomain/QdawaAPIs/public/index.php';

  // Storage URLs
  static const String baseStorageUrl = '$baseDomain/QdawaAPIs/public/storage';

  // AIP (AI Processing) URLs
  static const String aipBaseUrl = '$baseDomain/AIP';
  static const String aipProcessUrl = '$aipBaseUrl/processnew.php';
  static String aipInputUrl(String filePath) => '$aipBaseUrl/input/$filePath';

  // Legacy API endpoints (direct PHP files)
  static const String suggestionApiUrl = '$baseDomain/suggestion.php';
  static const String searchPatientApiUrl = '$baseDomain/search_patient.php';

  // Helper method to build full API endpoint URL
  static String buildApiUrl(String endpoint) {
    // Remove leading slash if present
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseApiUrl/$cleanEndpoint';
  }

  // Helper method to build storage file URL
  static String buildStorageUrl(String filePath) {
    // Remove leading slash if present
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseStorageUrl/$cleanPath';
  }

  // OneSignal Configuration
  static const String oneSignalAppId = 'f70ca8a1-e268-4034-9346-3ac590821fe7';
  static const String oneSignalApiKey = '';
}
