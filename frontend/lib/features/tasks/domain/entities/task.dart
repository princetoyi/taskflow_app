import 'package:equatable/equatable.dart';
import 'task_priority.dart';
import 'task_status.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime deadline;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    required this.deadline,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, description, status, priority, deadline, createdAt];
}
