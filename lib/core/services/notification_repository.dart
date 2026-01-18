import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/network/api_config.dart';

/// Notification Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

/// Notification Repository - handles API calls for device token management
class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// Register device FCM token with backend
  Future<bool> registerDeviceToken(String fcmToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';

      await _apiClient.post(
        ApiEndpoints.updateDeviceToken,
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );

      if (kDebugMode) {
        print('FCM token registered successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
      return false;
    }
  }

  /// Remove device token from backend (on logout)
  Future<bool> removeDeviceToken() async {
    try {
      await _apiClient.delete(ApiEndpoints.updateDeviceToken);

      if (kDebugMode) {
        print('FCM token removed successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing FCM token: $e');
      }
      return false;
    }
  }
}
