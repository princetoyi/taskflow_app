import 'package:flutter/material.dart';

class TeamMemberTile extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const TeamMemberTile({
    Key? key,
    required this.initials,
    required this.name,
    required this.subtitle,
    this.selected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFDEE2EA),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: selected ? const Color(0xFF2563EB) : const Color(0xFFEEF2FF),
              foregroundColor: selected ? Colors.white : const Color(0xFF2563EB),
              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFCED4DA)),
                color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
