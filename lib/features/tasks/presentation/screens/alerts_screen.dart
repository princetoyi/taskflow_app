import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskflow_app/core/widgets/notification_card.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alerts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Today · 6 new alerts', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  final tasks = state is TaskLoaded ? state.tasks : <Task>[];
                  return ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    children: [
                      NotificationCard(
                        label: '⚠ Overdue Alert',
                        title: tasks.isNotEmpty ? tasks.first.title : 'Safety checklist Zone C',
                        subtitle: 'Sarah K. · Past due 18h',
                        borderColor: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFFFFF2F2),
                        labelColor: const Color(0xFFDC2626),
                      ),
                      NotificationCard(
                        label: '✅ Task Completed',
                        title: tasks.length > 1 ? tasks[1].title : 'Staff scheduling Feb',
                        subtitle: 'Lena P. marked done · 1 hr ago',
                        borderColor: const Color(0xFF00C9A7),
                        backgroundColor: const Color(0xFFECFDF5),
                        labelColor: const Color(0xFF00C9A7),
                      ),
                      NotificationCard(
                        label: '📊 Progress Update',
                        title: tasks.length > 2 ? tasks[2].title : 'Warehouse inventory count',
                        subtitle: 'Sarah K. → 65% · 2 min ago',
                        borderColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEFF6FF),
                        labelColor: const Color(0xFF2563EB),
                      ),
                      const NotificationCard(
                        label: '🔒 Blocker Flagged',
                        title: 'Delivery route — Unit 6',
                        subtitle: 'Tom N. is blocked · needs attention',
                        borderColor: Color(0xFF7C3AED),
                        backgroundColor: Color(0xFFF5F3FF),
                        labelColor: Color(0xFF7C3AED),
                      ),
                      NotificationCard(
                        label: '📬 Task Assigned',
                        title: tasks.length > 3 ? tasks[3].title : 'Restock shelf row 7–12',
                        subtitle: 'Received by Sarah K. · 9:30 AM',
                        borderColor: const Color(0xFFF59E0B),
                        backgroundColor: const Color(0xFFFFFBEB),
                        labelColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
