import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/widgets/custom_bottom_navigation_bar.dart';
import 'package:taskflow_app/core/widgets/dashboard_stat_card.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskflow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
              builder: (context, state) {
                final tasks = state is TaskLoaded ? state.tasks : <Task>[];
                return Column(
                  children: [
                    _DashboardHeader(userName: authState.user.displayName, taskCount: tasks.length),
                    Expanded(child: _DashboardContent(tasks: tasks)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final int taskCount;

  const _DashboardHeader({required this.userName, required this.taskCount});

  @override
  Widget build(BuildContext context) {
    final initials = _avatarInitials(userName);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('${DateTime.now().weekdayName} · $taskCount active tasks', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFFFF5C35), shape: BoxShape.circle),
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _avatarInitials(String displayName) {
    if (displayName.isEmpty) return 'TM';
    final parts = displayName.split(' ');
    return parts.take(2).map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
  }
}

class _DashboardContent extends StatefulWidget {
  final List<Task> tasks;

  const _DashboardContent({required this.tasks});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.tasks.where((task) => task.status == TaskStatus.completed).length;
    final overdueCount = widget.tasks.where((task) => task.deadline.isBefore(DateTime.now()) && task.status != TaskStatus.completed).length;
    final activeCount = widget.tasks.where((task) => task.status != TaskStatus.completed).length;
    const blockedCount = 0;

    const teamWorkload = [
      {'name': 'Sarah K.', 'fill': 0.8, 'label': '6 tasks', 'color': Color(0xFF2563EB)},
      {'name': 'Marcus D.', 'fill': 0.55, 'label': '4 tasks', 'color': Color(0xFF00C9A7)},
      {'name': 'Lena P.', 'fill': 0.3, 'label': '2 tasks', 'color': Color(0xFFF59E0B)},
      {'name': 'Tom N.', 'fill': 0.25, 'label': '2 tasks', 'color': Color(0xFF7C3AED)},
    ];

    final recentTasks = widget.tasks.take(3).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.15,
                  children: [
                    DashboardStatCard(value: activeCount.toString(), label: 'Active Tasks', backgroundColor: const Color(0xFFEFF6FF), valueColor: const Color(0xFF2563EB)),
                    DashboardStatCard(value: overdueCount.toString(), label: 'Overdue', backgroundColor: const Color(0xFFFFF2F2), valueColor: const Color(0xFFDC2626)),
                    DashboardStatCard(value: completedCount.toString(), label: 'Completed', backgroundColor: const Color(0xFFECFDF5), valueColor: const Color(0xFF047857)),
                    DashboardStatCard(value: blockedCount.toString(), label: 'Blocked', backgroundColor: const Color(0xFFFFFBEB), valueColor: const Color(0xFF92400E)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _statusTab('All ${widget.tasks.length}', active: _selectedTab == 0),
                      _statusTab('Not Started ${widget.tasks.where((task) => task.status == TaskStatus.pending).length}', active: _selectedTab == 1),
                      _statusTab('In Progress ${widget.tasks.where((task) => task.status == TaskStatus.pending).length}', active: _selectedTab == 2),
                      _statusTab('Blocked $blockedCount', active: _selectedTab == 3, textColor: const Color(0xFF7C3AED), background: const Color(0xFFF5F3FF)),
                      _statusTab('Done $completedCount', active: _selectedTab == 4, textColor: const Color(0xFF047857), background: const Color(0xFFECFDF5)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Team Workload', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                ...teamWorkload.map((entry) => _buildWorkloadRow(entry['name'] as String, entry['fill'] as double, entry['label'] as String, entry['color'] as Color)).toList(),
                const SizedBox(height: 24),
                Text('Recent Updates', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                ...recentTasks.map((task) => _buildRecentUpdate(task)).toList(),
              ],
            ),
          ),
        ),
        CustomBottomNavigationBar(
          currentIndex: 0,
          onTap: _navigateBottom,
          items: const [
            BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
            BottomNavItem(icon: Icons.list_alt, label: 'Tasks'),
            BottomNavItem(icon: Icons.group, label: 'Team'),
            BottomNavItem(icon: Icons.bar_chart, label: 'Reports'),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkloadRow(String name, double fill, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFEFEFEF), borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                widthFactor: fill,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 42, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _statusTab(String label, {bool active = false, Color textColor = const Color(0xFF9EA3B0), Color background = const Color(0xFFF5F5F7)}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: active ? const Color(0xFF0D0D12) : background, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : textColor)),
      ),
    );
  }

  Widget _buildRecentUpdate(Task task) {
    final badgeColor = task.status == TaskStatus.completed ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF);
    final labelColor = task.status == TaskStatus.completed ? const Color(0xFF047857) : const Color(0xFF2563EB);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0F0F4))),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: labelColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Updated by ${task.userId} · now', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(task.status == TaskStatus.completed ? 'DONE' : 'IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor)),
          ),
        ],
      ),
    );
  }

  void _navigateBottom(int index) {
    switch (index) {
      case 1:
        GoRouter.of(context).go(AppRoutes.tasks);
        break;
      case 2:
        GoRouter.of(context).go(AppRoutes.atRiskTasks);
        break;
      case 3:
        GoRouter.of(context).go(AppRoutes.alerts);
        break;
      default:
        break;
    }
  }
}

extension DateTimeExtensions on DateTime {
  String get weekdayName {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
      default:
        return 'Sunday';
    }
  }
}
