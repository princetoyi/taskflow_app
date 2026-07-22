import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository})
      : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<WatchNotifications>(_onWatchNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    try {
      final notifications = await repository.getNotifications();

      if (notifications.isEmpty) {
        emit(const NotificationEmpty());
      } else {
        final unreadCount =
            notifications.where((n) => !n.isRead).length;

        emit(NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      }
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    // Preserve current state while refreshing
    if (state is NotificationLoaded) {
      try {
        final notifications = await repository.getNotifications();

        if (notifications.isEmpty) {
          emit(const NotificationEmpty());
        } else {
          final unreadCount =
              notifications.where((n) => !n.isRead).length;

          emit(NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          ));
        }
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    } else {
      add(const LoadNotifications());
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      try {
        await repository.markAsRead(event.notificationId);

        // Refresh list
        add(const LoadNotifications());
      } catch (e) {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.deleteNotification(event.notificationId);

      // Emit deleted state for UI feedback
      emit(NotificationDeleted(event.notificationId));

      // Refresh list after delete
      add(const LoadNotifications());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.clearAllNotifications();

      // Show empty state
      emit(const NotificationEmpty());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onWatchNotifications(
    WatchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationLoading());

      await emit.forEach(
        repository.watchNotifications(),
        onData: (List<NotificationModel> notifications) {
          if (notifications.isEmpty) {
            return const NotificationEmpty();
          }

          final unreadCount =
              notifications.where((n) => !n.isRead).length;

          return NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          );
        },
        onError: (error, stackTrace) {
          return NotificationError(error.toString());
        },
      );
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
