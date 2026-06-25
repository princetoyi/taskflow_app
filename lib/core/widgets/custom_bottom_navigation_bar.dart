import 'package:flutter/material.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final bool active;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.active = false,
  });
}

class CustomBottomNavigationBar extends StatelessWidget {
  final List<BottomNavItem> items;
  final ValueChanged<int> onTap;
  final int currentIndex;

  const CustomBottomNavigationBar({
    Key? key,
    required this.items,
    required this.onTap,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final selected = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 20, color: selected ? const Color(0xFF2563EB) : const Color(0xFF9EA3B0)),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? const Color(0xFF2563EB) : const Color(0xFF9EA3B0),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
