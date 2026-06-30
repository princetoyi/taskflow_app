// ignore_for_file: experimental_features
import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../data/models/notification_model.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient apiClient;

  NotificationRepositoryImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final data = await apiClient.get<dynamic>('/notifications');
      final items = data as List<dynamic>;
      return items
          .map((dynamic item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw Exception('Unable to load notifications: $error');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() async* {
    yield await getNotifications();

    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      try {
        yield await getNotifications();
      } catch (_) {
        // keep the previous stream alive; errors will be handled by the caller
      }
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await apiClient.put('/notifications/$notificationId/read');
    } catch (error) {
      throw Exception('Unable to mark notification as read: $error');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    // Backend does not currently support deleting notifications.
    return;
  }

  @override
  Future<void> clearAllNotifications() async {
    // Backend does not currently support clearing all notifications.
    return;
  }
}
