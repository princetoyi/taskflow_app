import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/entities/task.dart';
import '../domain/entities/task_status.dart';
import '../domain/repositories/task_repository.dart';
import '../presentation/bloc/task_bloc.dart';
import '../presentation/bloc/task_event.dart';
import '../presentation/bloc/task_state.dart';
import '../presentation/widgets/priority_badge.dart';
import '../presentation/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Task? initialTask;

  const TaskDetailScreen({Key? key, required this.taskId, this.initialTask})
      : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Future<Task?>? _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = widget.initialTask == null
        ? context.read<TaskRepository>().getTaskById(widget.taskId)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.initialTask ?? _findTask(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final taskToEdit = task ?? widget.initialTask;
              if (taskToEdit != null) {
                context.go(AppRoutes.taskCreate, extra: taskToEdit);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: task != null
          ? _buildTaskDetails(context, task)
          : _buildTaskFuture(context),
    );
  }

  Widget _buildTaskFuture(BuildContext context) {
    return FutureBuilder<Task?>(
      future: _taskFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        final task = snapshot.data;
        if (task == null) {
          return _buildErrorState(context, 'Task not found.');
        }

        return _buildTaskDetails(context, task);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _taskFuture =
                      context.read<TaskRepository>().getTaskById(widget.taskId);
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetails(BuildContext context, Task task) {
    final dueDate = '${task.deadline.toLocal()}'.split(' ')[0];
    final createdDate = '${task.createdAt.toLocal()}'.split(' ')[0];
    final isOverdue = task.deadline.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Text('Task overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                task.description.isEmpty
                    ? 'No description available.'
                    : task.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  StatusChip(status: task.status),
                  const SizedBox(width: 10),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _buildInfoTag(context, Icons.calendar_month, 'Due', dueDate,
                      isOverdue ? AppColors.warn : AppColors.accent2),
                  const SizedBox(width: 10),
                  _buildInfoTag(context, Icons.event, 'Created', createdDate,
                      AppColors.muted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
            context,
            'Description',
            task.description.isEmpty
                ? 'No description available.'
                : task.description),
        const SizedBox(height: 18),
        _buildSection(context, 'Deadline', dueDate),
        const SizedBox(height: 18),
        _buildSection(context, 'Created', createdDate),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () {
            context.read<TaskBloc>().add(ToggleTaskStatus(task));
          },
          icon: Icon(
              task.status == TaskStatus.completed ? Icons.undo : Icons.check),
          label: Text(task.status == TaskStatus.completed
              ? 'Mark pending'
              : 'Mark completed'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInfoTag(BuildContext context, IconData icon, String title,
      String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha((0.12 * 255).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Task? _findTask(BuildContext context) {
    final state = context.read<TaskBloc>().state;
    if (state is TaskLoaded) {
      final matches =
          state.tasks.where((task) => task.id == widget.taskId).toList();
      return matches.isNotEmpty ? matches.first : null;
    }
    return null;
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content:
              const Text('This action cannot be undone. Delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<TaskBloc>().add(DeleteTask(widget.taskId));
                context.pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
