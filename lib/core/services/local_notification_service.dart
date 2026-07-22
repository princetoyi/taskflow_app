import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'logger_service.dart';

/// LocalNotificationService handles displaying local notifications
/// and managing notification-related interactions
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotif =
      FlutterLocalNotificationsPlugin();

  /// Stream to track selected notifications
  final StreamController<String?> _selectNotificationController =
      StreamController<String?>.broadcast();

  Stream<String?> get selectNotificationStream =>
      _selectNotificationController.stream;

  /// Initialize local notifications service
  Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    // Combined initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings
    await _flutterLocalNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    LoggerService.info('✅ Local notifications initialized');
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'taskflow_notifications',
      'TaskFlow Notifications',
      description: 'Notification channel for TaskFlow app',
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Display a local notification
  Future<void> show(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'taskflow_notifications',
            'TaskFlow Notifications',
            channelDescription: 'Notification channel for TaskFlow app',
            importance: Importance.max,
            priority: Priority.max,
            enableLights: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotif.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      LoggerService.error('❌ Error showing notification: $e', e);
    }
  }

  /// Cancel a notification
  Future<void> cancel(int id) async {
    try {
      await _flutterLocalNotif.cancel(id);
    } catch (e) {
      LoggerService.error('❌ Error canceling notification: $e', e);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _flutterLocalNotif.cancelAll();
    } catch (e) {
      LoggerService.error('❌ Error canceling all notifications: $e', e);
    }
  }

  /// Handle when user taps on notification (iOS)
  Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    _selectNotificationController.add(payload);
  }

  /// Handle when user taps on notification (Android/iOS)
  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    _selectNotificationController.add(payload);
  }

  /// Dispose resources
  void dispose() {
    _selectNotificationController.close();
  }
}
