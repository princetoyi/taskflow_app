import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskflow_app/core/widgets/notification_card.dart';
import 'package:taskflow_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:taskflow_app/features/notifications/presentation/widgets/empty_notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C0C14),
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading || state is NotificationInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError) {
              return _ErrorState(
                message: state.message,
                onRetry: () => context.read<NotificationBloc>().add(const LoadNotifications()),
              );
            }

            if (state is NotificationEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(const RefreshNotifications());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 120,
                    child: EmptyNotificationState(
                      onRefresh: () => context.read<NotificationBloc>().add(const RefreshNotifications()),
                    ),
                  ),
                ),
              );
            }

            if (state is NotificationLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(const RefreshNotifications());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  itemCount: state.notifications.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _Header(unreadCount: state.unreadCount);
                    }

                    final notification = state.notifications[index - 1];
                    return NotificationCard(
                      label: notification.typeDisplayName,
                      title: notification.title,
                      subtitle: notification.description,
                      borderColor: _colorFromHex(notification.typeColorHex),
                      backgroundColor: _colorFromHex(notification.typeColorHex).withAlpha((0.18 * 255).round()),
                      labelColor: _colorFromHex(notification.typeColorTextHex),
                      isRead: notification.isRead,
                      timestamp: _formatTimestamp(notification.createdAt),
                      onTap: () {
                        context.read<NotificationBloc>().add(MarkNotificationRead(notification.id));
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime when) {
    final difference = DateTime.now().difference(when);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  static Color _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;

  const _Header({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent alerts',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          unreadCount > 0 ? '$unreadCount unread' : 'No unread notifications',
          style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load notifications',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
