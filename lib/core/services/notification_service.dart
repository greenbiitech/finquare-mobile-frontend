import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.showNotification(message);
}

/// Notification channel for Android
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'finsquare_high_importance_channel',
  'FinSquare Notifications',
  description: 'This channel is used for important FinSquare notifications.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Callback type for token refresh events
typedef TokenRefreshCallback = Future<void> Function(String token);

/// Singleton notification service handling FCM and local notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;
  TokenRefreshCallback? _onTokenRefreshCallback;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Get FCM token
    await _getFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _onTokenRefresh(token);
    });

    _isInitialized = true;
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Get FCM token
  Future<String?> _getFcmToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }
      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Handle FCM token refresh
  void _onTokenRefresh(String token) {
    if (kDebugMode) {
      print('FCM Token refreshed: $token');
    }
    // Call the callback if set (to register with backend)
    _onTokenRefreshCallback?.call(token);
  }

  /// Set callback for token refresh events (used to register with backend)
  void setTokenRefreshCallback(TokenRefreshCallback callback) {
    _onTokenRefreshCallback = callback;
  }

  /// Get FCM token (public method for registration)
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    return await _getFcmToken();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
    }
    showNotification(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }
    // TODO: Navigate based on notification data
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }
    if (response.payload != null) {
      final _ = jsonDecode(response.payload!);
      // TODO: Navigate based on notification data
    }
  }

  /// Show a notification (local)
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show a custom local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Show an in-app notification (non-intrusive)
  /// This is handled by the SnackbarService

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear a specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
