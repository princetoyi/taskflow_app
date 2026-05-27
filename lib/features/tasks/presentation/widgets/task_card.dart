import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import 'priority_badge.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.deadline.isBefore(DateTime.now()) && task.status != TaskStatus.completed;
    final deadlineColor = isOverdue ? AppColors.warn : AppColors.muted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusDot(task.status),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.description.isEmpty ? 'No description added yet.' : task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        task.status == TaskStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: task.status == TaskStatus.completed ? AppColors.mint : AppColors.accent,
                        size: 28,
                      ),
                      tooltip: task.status == TaskStatus.completed ? 'Mark as pending' : 'Mark as completed',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildDeadlineBadge(deadlineColor, task.deadline),
                    const Spacer(),
                    PriorityBadge(priority: task.priority),
                    const SizedBox(width: 8),
                    StatusChip(status: task.status),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
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

  Widget _buildStatusDot(TaskStatus status) {
    final color = status == TaskStatus.completed ? AppColors.mint : AppColors.accent;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((0.25 * 255).round()),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 6),
    );
  }

  Widget _buildDeadlineBadge(Color color, DateTime deadline) {
    final deadlineText = '${deadline.toLocal()}'.split(' ')[0];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            deadlineText,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
