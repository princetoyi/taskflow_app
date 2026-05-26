import 'package:flutter/material.dart';
import '../../domain/entities/task_status.dart';

class StatusChip extends StatelessWidget {
  final TaskStatus status;

  const StatusChip({Key? key, required this.status}) : super(key: key);

  Color get _backgroundColor {
    return status == TaskStatus.completed ? Colors.green.shade100 : Colors.blue.shade100;
  }

  Color get _textColor {
    return status == TaskStatus.completed ? Colors.green.shade900 : Colors.blue.shade900;
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status == TaskStatus.completed ? 'Completed' : 'Pending'),
      backgroundColor: _backgroundColor,
      labelStyle: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
