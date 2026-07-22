import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/core/widgets/progress_slider.dart';
import 'package:taskflow_app/core/widgets/status_badge.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_event.dart';
import 'package:taskflow_app/features/tasks/presentation/widgets/priority_badge.dart';
import 'package:taskflow_app/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class EmployeeTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Task? initialTask;

  const EmployeeTaskDetailScreen({Key? key, required this.taskId, this.initialTask}) : super(key: key);

  @override
  State<EmployeeTaskDetailScreen> createState() => _EmployeeTaskDetailScreenState();
}

class _EmployeeTaskDetailScreenState extends State<EmployeeTaskDetailScreen> {
  Future<Task?>? _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = widget.initialTask == null ? context.read<TaskRepository>().getTaskById(widget.taskId) : null;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.initialTask;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: task != null ? _buildContent(context, task) : FutureBuilder<Task?>(
          future: _taskFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildError(context);
            }
            return _buildContent(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Task task) {
    final progress = _taskProgress(task);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 8),
            const Text('Task Detail', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF0D0D12), borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Assigned by ${task.userId} · Due ${_formattedDate(task.deadline)}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.topLeft,
                child: PriorityBadge(priority: task.priority),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w800, letterSpacing: 0.08)),
                      const SizedBox(height: 4),
                      Text('$progress%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                    ],
                  ),
                  StatusBadge(
                    label: task.status == TaskStatus.completed ? 'COMPLETED' : 'IN PROGRESS',
                    textColor: task.status == TaskStatus.completed ? const Color(0xFF047857) : const Color(0xFF2563EB),
                    backgroundColor: task.status == TaskStatus.completed ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ProgressSlider(progress: progress, activeColor: const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0%', style: TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
                  Text('100%', style: TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _badge('25%'),
                  _badge('50%'),
                  _badge('75%', active: true),
                  _badge('100% ✓', active: true),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF8F8FB), borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00C9A7), shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Online · All changes synced', style: TextStyle(fontSize: 10, color: Color(0xFF0F172A)))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _infoTile('Created', _formattedDate(task.createdAt)),
            const SizedBox(width: 8),
            _infoTile('Assigned', _formattedDate(task.createdAt)),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Activity Timeline', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.08, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        _timelineEntry('🚀', 'Task assigned to ${task.userId}', 'Feb 25 · 8:03 AM'),
        _timelineEntry('▶️', 'Status → In Progress (0%)', 'Feb 26 · 7:45 AM'),
        _timelineEntry('📊', 'Progress updated to $progress%', 'Feb 26 · 1:15 PM · Now'),
        const SizedBox(height: 18),
        const Text('Audit Log', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.08, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        _auditEntry('📝', 'Sarah K. updated progress → $progress%', 'uid_sarah_k · Feb 26 13:15:04'),
        _auditEntry('🚀', 'J. Mokoena assigned task', 'uid_employer_jm · Feb 25 08:03:42'),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            if (task.status != TaskStatus.completed) {
              context.read<TaskBloc>().add(UpdateTaskRequested(task: task.copyWith(status: TaskStatus.completed)));
            }
          },
          child: Text(task.status == TaskStatus.completed ? 'Already Completed' : 'Mark Completed'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Task not found.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go(AppRoutes.tasks), child: const Text('Return to tasks')),
        ],
      ),
    );
  }

  int _taskProgress(Task task) {
    if (task.status == TaskStatus.completed) return 100;
    switch (task.priority) {
      case TaskPriority.high:
        return 65;
      case TaskPriority.medium:
        return 30;
      case TaskPriority.low:
        return 10;
    }
  }

  String _formattedDate(DateTime value) {
    return '${value.month}/${value.day}/${value.year}';
  }

  static Widget _badge(String label, {bool active = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? const Color(0xFF2563EB) : const Color(0xFF6B7280))),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF7F7FA), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280), fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _timelineEntry(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: const Color(0xFFF8F8FB), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditEntry(String icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FB), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
