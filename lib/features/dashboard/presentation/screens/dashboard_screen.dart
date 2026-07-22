import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskflow_app/core/widgets/dashboard_stat_card.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_event.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(const FetchTasksRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isManager = authState.user.isManager;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text('TaskFlow Dashboard'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TaskBloc>().add(const FetchTasksRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(authState.user.displayName),
                    const SizedBox(height: 24),
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        if (state is TaskLoading) {
                          return _buildStatisticsSkeleton();
                        }
                        if (state is TaskError) {
                          return _buildErrorWidget(state.message);
                        }
                        if (state is TaskLoaded) {
                          return _buildStatistics(state.tasks);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Recent Tasks'),
                    const SizedBox(height: 12),
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        if (state is TaskLoading) {
                          return _buildTaskListSkeleton();
                        }
                        if (state is TaskError) {
                          return _buildErrorWidget(state.message);
                        }
                        if (state is TaskLoaded) {
                          if (state.tasks.isEmpty) {
                            return _buildEmptyState();
                          }

                          final recentTasks = state.tasks.take(5).toList();
                          return Column(
                            children: recentTasks.map((task) => _buildTaskCard(context, task)).toList(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (isManager) ...[
                      const SizedBox(height: 32),
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 12),
                      _buildManagerActions(context),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const CustomBottomNavigationBar(
            currentIndex: 0,
            items: [
              BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
              BottomNavItem(icon: Icons.list_alt, label: 'Tasks'),
              BottomNavItem(icon: Icons.group, label: 'Team'),
              BottomNavItem(icon: Icons.bar_chart, label: 'Reports'),
            ],
            onTap: _noopTap,
          ),
        );
      },
    );
  }

  Widget _buildGreeting(String displayName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${displayName.isNotEmpty ? displayName : 'User'}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your task overview for today",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatistics(List<Task> tasks) {
    final completed = tasks.where((task) => task.status == TaskStatus.completed).length;
    final pending = tasks.where((task) => task.status != TaskStatus.completed).length;
    final overdue = tasks
        .where((task) => task.status != TaskStatus.completed && task.deadline.isBefore(DateTime.now()))
        .length;
    final highPriority = tasks.where((task) => task.priority == TaskPriority.high).length;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          DashboardStatCard(
            value: tasks.length.toString(),
            label: 'Total Tasks',
            backgroundColor: const Color(0xFFEFF6FF),
            valueColor: const Color(0xFF2563EB),
          ),
          DashboardStatCard(
            value: completed.toString(),
            label: 'Completed',
            backgroundColor: const Color(0xFFECFDF5),
            valueColor: const Color(0xFF047857),
          ),
          DashboardStatCard(
            value: pending.toString(),
            label: 'Pending',
            backgroundColor: const Color(0xFFFFFBEB),
            valueColor: const Color(0xFFF59E0B),
          ),
          DashboardStatCard(
            value: overdue.toString(),
            label: 'Overdue',
            backgroundColor: const Color(0xFFFFF2F2),
            valueColor: const Color(0xFFDC2626),
          ),
          DashboardStatCard(
            value: highPriority.toString(),
            label: 'High Priority',
            backgroundColor: const Color(0xFFF5F3FF),
            valueColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSkeleton() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskListSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (value) {
            if (value != null) {
              final updatedTask = task.copyWith(status: value ? TaskStatus.completed : TaskStatus.pending);
              context.read<TaskBloc>().add(UpdateTaskRequested(task: updatedTask));
            }
          },
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.description.isNotEmpty ? task.description : 'No description',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(task.priority.label.toUpperCase(), style: const TextStyle(fontSize: 10)),
          backgroundColor: _priorityColor(task.priority.label),
        ),
        onTap: () => context.push(AppRoutes.taskDetail.replaceFirst(':id', task.id), extra: task),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildManagerActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionCard(
          context,
          'Team Members',
          Icons.people_outline,
          Colors.blue,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team management coming soon'))),
        ),
        _buildActionCard(
          context,
          'Create Task',
          Icons.add_circle_outline,
          Colors.green,
          () => context.push(AppRoutes.taskCreate),
        ),
        _buildActionCard(
          context,
          'Reports',
          Icons.bar_chart_outlined,
          Colors.orange,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reports coming soon'))),
        ),
        _buildActionCard(
          context,
          'Analytics',
          Icons.analytics_outlined,
          Colors.purple,
          () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics coming soon'))),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first task to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error loading tasks',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600),
                ),
                Text(message, style: TextStyle(color: Colors.red[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red[100]!;
      case 'medium':
        return Colors.orange[100]!;
      case 'low':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  static void _noopTap(int _) {}
}

