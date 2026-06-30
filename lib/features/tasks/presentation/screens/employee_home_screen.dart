import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';
import 'package:taskflow_app/features/tasks/presentation/widgets/employee_task_card.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F3EF),
          body: SafeArea(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                final tasks = taskState is TaskLoaded ? taskState.tasks : <Task>[];
                final openTasks = tasks.where((task) => task.status != TaskStatus.completed).toList();
                final dueToday = openTasks.where((task) => task.deadline.isAtSameDay(DateTime.now())).toList();
                final overdue = openTasks.where((task) => task.deadline.isBefore(DateTime.now())).toList();
                final dueTodayCount = dueToday.length;
                final overdueCount = overdue.length;
                final totalOpen = openTasks.length;

                return Column(
                  children: [
                    _buildGreeting(context, authState.user.displayName, dueTodayCount, overdueCount, totalOpen),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Offline · 1 update pending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                            const SizedBox(width: 10),
                            Text('Syncs on reconnect', style: TextStyle(color: Colors.white.withAlpha((0.55 * 255).round()), fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    if (overdue.isNotEmpty) _buildOverdueCard(overdue.first),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            child: Text('Due Today', style: Theme.of(context).textTheme.labelLarge),
                          ),
                          if (dueToday.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 18),
                              child: Text('No tasks due today. Check back later.', style: TextStyle(color: Color(0xFF6B7280))),
                            )
                          else
                            ...dueToday.map((task) {
                              return EmployeeTaskCard(
                                task: task,
                                progress: _buildProgress(task),
                                showBlockedButton: true,
                                onTap: () => context.go(AppRoutes.taskDetail.replaceFirst(':id', task.id), extra: task),
                                onBlock: () {},
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            items: const [
              BottomNavItem(icon: Icons.home, label: 'My Work'),
              BottomNavItem(icon: Icons.list_alt, label: 'All Tasks'),
              BottomNavItem(icon: Icons.notifications, label: 'Alerts'),
              BottomNavItem(icon: Icons.person, label: 'Profile'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context, String displayName, int dueTodayCount, int overdueCount, int totalOpen) {
    final name = displayName.isEmpty ? 'Team member' : displayName.split(' ').first;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D0D12), Color(0xFF1C1C30)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thursday · Feb 26', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Good morning, $name 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('$dueTodayCount tasks to tackle today', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBubble('$dueTodayCount', 'Due Today', const Color(0xFF00C9A7)),
              const SizedBox(width: 6),
              _buildStatBubble('$overdueCount', 'Overdue', const Color(0xFFFF5C35)),
              const SizedBox(width: 6),
              _buildStatBubble('$totalOpen', 'Total Open', const Color(0xFF7C9EFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String value, String label, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withAlpha((0.08 * 255).round()), borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueCard(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠ Overdue', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E), letterSpacing: 0.1)),
            const SizedBox(height: 10),
            Text(task.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Was due Feb 25 · Tap to update', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  int _buildProgress(Task task) {
    switch (task.priority) {
      case TaskPriority.high:
        return 65;
      case TaskPriority.medium:
        return 30;
      case TaskPriority.low:
        return 10;
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        GoRouter.of(context).go(AppRoutes.tasks);
        break;
      case 2:
        GoRouter.of(context).go(AppRoutes.alerts);
        break;
      case 3:
        GoRouter.of(context).go(AppRoutes.settings);
        break;
      default:
        break;
    }
  }
}

extension on DateTime {
  bool isAtSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
