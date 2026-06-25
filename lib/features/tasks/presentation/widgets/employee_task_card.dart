import 'package:flutter/material.dart';
import 'package:taskflow_app/core/widgets/progress_slider.dart';
import 'package:taskflow_app/core/widgets/status_badge.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import 'priority_badge.dart';

class EmployeeTaskCard extends StatelessWidget {
  final Task task;
  final int progress;
  final VoidCallback onTap;
  final bool showBlockedButton;
  final VoidCallback? onBlock;

  const EmployeeTaskCard({
    Key? key,
    required this.task,
    required this.progress,
    required this.onTap,
    this.showBlockedButton = false,
    this.onBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.deadline.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final deadlineLabel = isOverdue ? 'Overdue' : 'Due ${_formattedDate(task.deadline)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDEE2EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(deadlineLabel,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    PriorityBadge(priority: task.priority),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: ProgressSlider(progress: progress, activeColor: _progressColor(progress))),
                    const SizedBox(width: 10),
                    Text('$progress%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(
                      label: task.status == TaskStatus.completed ? 'Done' : 'In Progress',
                      textColor: task.status == TaskStatus.completed ? const Color(0xFF047857) : const Color(0xFF2563EB),
                      backgroundColor: task.status == TaskStatus.completed ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                    ),
                    const Spacer(),
                    if (showBlockedButton && onBlock != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: onBlock,
                          child: const Text('Mark as Blocked', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _progressColor(int progress) {
    if (progress >= 75) return const Color(0xFF2563EB);
    if (progress >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  String _formattedDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
