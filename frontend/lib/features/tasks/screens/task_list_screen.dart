import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../domain/entities/task.dart';
import '../presentation/bloc/task_bloc.dart';
import '../presentation/bloc/task_event.dart';
import '../presentation/bloc/task_state.dart';
import '../presentation/widgets/empty_state_widget.dart';
import '../presentation/widgets/loading_skeleton.dart';
import '../presentation/widgets/task_card.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';

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
            onPressed: () => context.go(AppRoutes.taskCreate),
            label: const Text('New Task'),
            icon: const Icon(Icons.add),
            backgroundColor: AppColors.accent,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Authenticated state) {
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
          Text('Today · 4 tasks to tackle', style: Theme.of(context).textTheme.bodyMedium),
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
                const Text('Good morning, Sarah 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('You have 4 tasks to tackle today', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatPill('4', 'Due Today', AppColors.mint),
                    const SizedBox(width: 10),
                    _buildStatPill('1', 'Overdue', AppColors.accent),
                    const SizedBox(width: 10),
                    _buildStatPill('6', 'Total Open', const Color(0xFF7C9EFF)),
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
                    onPressed: () => context.read<TaskBloc>().add(const LoadTasks()),
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
            onAction: () => context.go(AppRoutes.taskCreate),
          );
        }

        final tasks = state is TaskLoaded ? state.tasks : <Task>[];

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TaskBloc>().add(const LoadTasks());
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () => context.go(AppRoutes.taskDetail.replaceFirst(':id', task.id), extra: task),
                onToggleStatus: () => context.read<TaskBloc>().add(ToggleTaskStatus(task)),
                onDelete: () => _confirmDelete(context, task.id),
              );
            },
          ),
        );
      },
    );
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

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: const Text('Are you sure you want to remove this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<TaskBloc>().add(DeleteTask(taskId));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
