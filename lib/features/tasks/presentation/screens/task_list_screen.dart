import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/constants/app_colors.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_event.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';
import 'package:taskflow_app/features/tasks/presentation/widgets/empty_state_widget.dart';
import 'package:taskflow_app/features/tasks/presentation/widgets/loading_skeleton.dart';
import 'package:taskflow_app/features/tasks/presentation/widgets/task_card.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: Text('Please sign in to access tasks.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, authState),
                Expanded(child: _buildTaskBody(context)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.taskCreate),
            label: const Text('New Task'),
            icon: const Icon(Icons.add),
            backgroundColor: AppColors.accent,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Authenticated state) {
    final tasks = context.select<TaskBloc, List<Task>>((bloc) => (bloc.state is TaskLoaded) ? (bloc.state as TaskLoaded).tasks : <Task>[]);
    final dueTodayCount = tasks.where((task) => task.status != TaskStatus.completed && _isSameDay(task.deadline, DateTime.now())).length;
    final overdueCount = tasks.where((task) => task.status != TaskStatus.completed && task.deadline.isBefore(DateTime.now())).length;
    final totalOpenCount = tasks.where((task) => task.status != TaskStatus.completed).length;
    final greeting = _buildGreeting();
    final displayName = state.user.displayName.isNotEmpty ? state.user.displayName.split(' ').first : 'there';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Work',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.accent2,
                tooltip: 'Settings',
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accent2, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _avatarInitials(state.user.displayName, state.user.email),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Today · $totalOpenCount tasks to tackle', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $displayName 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                Text('You have $totalOpenCount tasks to tackle today', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatPill('$dueTodayCount', 'Due Today', AppColors.mint),
                    const SizedBox(width: 10),
                    _buildStatPill('$overdueCount', 'Overdue', AppColors.accent),
                    const SizedBox(width: 10),
                    _buildStatPill('$totalOpenCount', 'Total Open', const Color(0xFF7C9EFF)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBody(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const LoadingSkeleton();
        }

        if (state is TaskError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<TaskBloc>().add(const FetchTasksRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TaskLoaded && state.tasks.isEmpty) {
          return EmptyStateWidget(
            title: 'No tasks yet',
            description: 'Create a task to begin tracking work and deadlines.',
            actionLabel: 'Create task',
            onAction: () => context.push(AppRoutes.taskCreate),
          );
        }

        final tasks = state is TaskLoaded ? state.tasks : <Task>[];

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TaskBloc>().add(const FetchTasksRequested());
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await _confirmDelete(context, task.id);
                },
                onDismissed: (_) {
                  context.read<TaskBloc>().add(DeleteTask(task.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task removed')), 
                  );
                },
                child: TaskCard(
                  task: task,
                  onTap: () => context.push(AppRoutes.taskDetail.replaceFirst(':id', task.id), extra: task),
                  onToggleStatus: () => context.read<TaskBloc>().add(UpdateTask(_toggleStatus(task))),
                  onDelete: () async {
                    final taskBloc = context.read<TaskBloc>();
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await _confirmDelete(context, task.id);
                    if (confirmed) {
                      taskBloc.add(DeleteTask(task.id));
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Task removed')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  static bool _isSameDay(DateTime? value, DateTime reference) {
    if (value == null) {
      return false;
    }
    return value.year == reference.year && value.month == reference.month && value.day == reference.day;
  }

  Widget _buildStatPill(String value, String label, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accentColor)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String taskId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: const Text('Are you sure you want to remove this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Task _toggleStatus(Task task) {
    final status = task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed;
    return Task(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      status: status,
      priority: task.priority,
      deadline: task.deadline,
      createdAt: task.createdAt,
    );
  }

  static String _avatarInitials(String displayName, String email) {
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName.substring(0, 2).toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }
}
