import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_priority.dart';

class TaskFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TaskPriority selectedPriority;
  final DateTime? selectedDeadline;
  final ValueChanged<TaskPriority?> onPriorityChanged;
  final VoidCallback onPickDeadline;

  const TaskFormFields({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedPriority,
    required this.selectedDeadline,
    required this.onPriorityChanged,
    required this.onPickDeadline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title'),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title.';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<TaskPriority>(
          initialValue: selectedPriority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: TaskPriority.values
              .map(
                (priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority.label),
                ),
              )
              .toList(),
          onChanged: onPriorityChanged,
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onPickDeadline,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Deadline'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDeadline != null
                      ? '${selectedDeadline!.toLocal()}'.split(' ')[0]
                      : 'Choose a deadline',
                  style: TextStyle(
                    color: selectedDeadline != null
                        ? AppColors.ink
                        : AppColors.textSecondary,
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
