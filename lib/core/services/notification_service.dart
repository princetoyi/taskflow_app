import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import 'storage_service.dart';

import 'dart:convert';
import 'local_notification_service.dart';

typedef OnNotificationTap = void Function(Map<String, dynamic> data);

class NotificationService {
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late ApiClient _apiClient;
  late StorageService _storageService;
  late LocalNotificationService _localNotif;

  OnNotificationTap? _onNotificationTap;

  /// Initialize notification service
  /// Must be called in main() before running the app
  Future<void> initialize({
    required ApiClient apiClient,
    required StorageService storageService,
    required LocalNotificationService localNotificationService,
    OnNotificationTap? onNotificationTap,
  }) async {
    _apiClient = apiClient;
    _storageService = storageService;
    _localNotif = localNotificationService;
    _onNotificationTap = onNotificationTap;

    await requestPermission();

    // Setup token refresh listener
    await _setupTokenRefresh();

    // Setup foreground notification handler
    _setupForegroundNotificationHandler();

    // Handle notification taps (when app is in foreground or background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Check if app was launched from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App launched from notification');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ Notification service initialized');
  }

  /// Request notification permissions (especially important for iOS)
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
        '🔔 Notification permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission denied.');
    }
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Register FCM token with backend
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final previous = await _storageService.getFcmToken();
      if (previous == token) return;

      await _storageService.saveFcmToken(token);
      await _apiClient.post('/notifications/fcm-token', data: {'fcm_token': token});

      debugPrint('✅ FCM token registered: $token');
    } on DioException catch (error) {
      debugPrint('Failed to register FCM token: ${error.message}');
    } catch (error) {
      debugPrint('FCM registration failure: $error');
    }
  }

  /// Register or refresh the FCM token after login/authentication.
  Future<void> registerToken() async {
    await _registerToken();
  }

  /// Setup listener for token refresh
  Future<void> _setupTokenRefresh() async {
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 FCM token refreshed: $newToken');
      _registerToken();
    });
  }

  /// Setup foreground notification handler
  void _setupForegroundNotificationHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '🔔 Received foreground message: ${message.notification?.title}');
      _displayNotification(message);
    });
  }

  /// Display local notification from Firebase message
  Future<void> _displayNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;

      if (notification != null) {
        await _localNotif.show(
          notification.hashCode,
          notification.title ?? 'TaskFlow',
          notification.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    } catch (e) {
      debugPrint('❌ Error displaying notification: $e');
    }
  }

  /// Handle notification tap and invoke callback
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      _onNotificationTap?.call(data);
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Get messaging instance
  FirebaseMessaging get messaging => _messaging;
}

/// Background message handler - must be a top-level function
/// This is called when app is terminated or in background (Android)
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  debugPrint(
      '🔔 Handling background message: ${message.notification?.title}');
}
