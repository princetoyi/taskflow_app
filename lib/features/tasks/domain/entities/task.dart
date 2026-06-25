import 'package:equatable/equatable.dart';
import 'task_priority.dart';
import 'task_status.dart';

class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime deadline;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    required this.deadline,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, title, description, status, priority, deadline, createdAt];
}
