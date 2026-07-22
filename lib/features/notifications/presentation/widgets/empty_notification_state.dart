import 'package:flutter/material.dart';

class EmptyNotificationState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const EmptyNotificationState({Key? key, this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(18),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Notifications will appear here when new activity arrives.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRefresh,
              child: const Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }
}
