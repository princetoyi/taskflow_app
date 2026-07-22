part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications from repository
class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

/// Refresh notifications (pull-to-refresh)
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

/// Mark notification as read
class MarkNotificationRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Delete a notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Clear all notifications
class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

/// Handle incoming remote message
class OnRemoteMessageReceived extends NotificationEvent {
  final Map<String, dynamic> data;

  const OnRemoteMessageReceived(this.data);

  @override
  List<Object?> get props => [data];
}

/// Watch notifications real-time
class WatchNotifications extends NotificationEvent {
  const WatchNotifications();
}
