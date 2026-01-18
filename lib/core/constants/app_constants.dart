/// Application-wide constants
abstract class AppConstants {
  static const String appName = 'FinSquare';
  static const String appVersion = '1.0.0';

  // API Configuration (to be updated)
  static const String baseUrl = '';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
