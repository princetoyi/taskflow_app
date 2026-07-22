import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color backgroundColor;
  final Color labelColor;
  final bool isRead;
  final String? timestamp;
  final VoidCallback? onTap;

  const NotificationCard({
    Key? key,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.backgroundColor,
    required this.labelColor,
    this.isRead = true,
    this.timestamp,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: Colors.white.withAlpha((0.08 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 4, right: 10),
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : const Color(0xFFFF5C35),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(width: 12),
              Text(
                timestamp!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
