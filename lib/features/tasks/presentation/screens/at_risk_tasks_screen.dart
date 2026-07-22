import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';
import 'package:taskflow_app/routes/app_routes.dart';

class AtRiskTasksScreen extends StatelessWidget {
  const AtRiskTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('At-Risk Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('2 tasks may miss deadline', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = state is TaskLoaded ? state.tasks : <Task>[];
        final atRisk = tasks.where((task) => task.deadline.isBefore(DateTime.now().add(const Duration(hours: 24))) && task.status != TaskStatus.completed).toList();

        if (atRisk.isEmpty) {
          return const Center(child: Text('No at-risk tasks at the moment.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
          itemCount: atRisk.length,
          itemBuilder: (context, index) {
            final task = atRisk[index];
            return _buildRiskCard(context, task, index == atRisk.length - 1);
          },
        );
      },
    );
  }

  Widget _buildRiskCard(BuildContext context, Task task, bool isLast) {
    final dueIn = task.deadline.difference(DateTime.now());
    final hours = dueIn.inHours;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 20 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFDE68A))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${task.userId} · Due in ${hours > 0 ? '$hours h' : 'less than 1 h'} ${dueIn.inMinutes % 60}m', style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFF8E5), borderRadius: BorderRadius.circular(12)),
                child: const Text('⚠ AT-RISK', style: TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Progress: 30% · needs 70% more', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.taskDetail.replaceFirst(':id', task.id), extra: task),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB)))),
                  child: const Text('👁 View Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('→ Nudge Worker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
