import '../../data/models/notification_model.dart';

abstract class NotificationRepository {
	Future<List<NotificationModel>> getNotifications();
	Stream<List<NotificationModel>> watchNotifications();
	Future<void> markAsRead(String notificationId);
	Future<void> deleteNotification(String notificationId);
	Future<void> clearAllNotifications();
}