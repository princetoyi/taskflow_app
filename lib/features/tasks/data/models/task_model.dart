import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';

part 'task_model.g.dart';

// ── Custom JSON converters ────────────────────────────────────────────────────

/// Backend sends `completed: true/false` (boolean).
/// We map that to the [TaskStatus] enum: true → completed, false → pending.
TaskStatus _statusFromJson(bool completed) =>
    completed ? TaskStatus.completed : TaskStatus.pending;

bool _statusToJson(TaskStatus status) => status == TaskStatus.completed;

/// Backend sends `priority: "low" | "medium" | "high"` (string).
TaskPriority _priorityFromJson(String value) =>
    TaskPriority.fromValue(value);

String _priorityToJson(TaskPriority priority) => priority.value;

// ─────────────────────────────────────────────────────────────────────────────

@JsonSerializable(explicitToJson: true)
class TaskModel extends Task {
  @JsonKey(name: 'owner_uid')
  @override
  final String userId;

  @JsonKey(name: 'completed', fromJson: _statusFromJson, toJson: _statusToJson)
  @override
  final TaskStatus status;

  @JsonKey(name: 'created_at')
  @override
  final DateTime createdAt;

  const TaskModel({
    required super.id,
    required this.userId,
    required super.title,
    super.description = '',
    required this.status,
    super.priority = TaskPriority.medium,
    required super.deadline,
    required this.createdAt,
  }) : super(userId: userId, status: status, createdAt: createdAt);

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  /// Request body payload for creating a task.
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority.value,
      'deadline': deadline.toIso8601String(),
    };
  }

  /// Request body payload for updating a task.
  Map<String, dynamic> toUpdateJson() {
    return {
      if (title.isNotEmpty) 'title': title,
      'description': description,
      'completed': status == TaskStatus.completed,
      'priority': priority.value,
      'deadline': deadline.toIso8601String(),
    };
  }

  @override
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return TaskModel(
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

  factory TaskModel.fromTask(Task task) {
    return TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      deadline: task.deadline,
      createdAt: task.createdAt,
    );
  }
}
