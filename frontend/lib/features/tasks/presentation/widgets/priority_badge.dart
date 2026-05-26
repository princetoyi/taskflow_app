import 'package:flutter/material.dart';
import '../../domain/entities/task_priority.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({Key? key, required this.priority}) : super(key: key);

  Color get _backgroundColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade100;
      case TaskPriority.medium:
        return Colors.orange.shade100;
      case TaskPriority.high:
        return Colors.red.shade100;
    }
  }

  Color get _textColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade800;
      case TaskPriority.medium:
        return Colors.orange.shade800;
      case TaskPriority.high:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(priority.label),
      backgroundColor: _backgroundColor,
      labelStyle: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
