import 'dart:async';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';

class MockTaskRepository implements TaskRepository {
  final List<TaskModel> _tasks = [
    TaskModel(
      id: 'task-1',
      userId: 'user-1',
      title: 'Design Phase 3 UX',
      description: 'Finalize forms, task cards, and detail navigation.',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      deadline: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TaskModel(
      id: 'task-2',
      userId: 'user-1',
      title: 'Sync backend contract',
      description: 'Confirm API schema with FastAPI team and update models.',
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      deadline: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    TaskModel(
      id: 'task-3',
      userId: 'user-1',
      title: 'Prepare release notes',
      description: 'Draft release summary for stakeholder review.',
      status: TaskStatus.completed,
      priority: TaskPriority.low,
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    TaskModel(
      id: 'task-4',
      userId: 'user-1',
      title: 'Review task metrics',
      description: 'Analyze completion velocity and overdue tasks.',
      status: TaskStatus.pending,
      priority: TaskPriority.high,
      deadline: DateTime.now().subtract(const Duration(hours: 12)),
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    TaskModel(
      id: 'task-5',
      userId: 'user-1',
      title: 'Launch mobile smoke tests',
      description: 'Validate routing, error handling, and authentication.',
      status: TaskStatus.completed,
      priority: TaskPriority.medium,
      deadline: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<Task> createTask(Task task) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final model = TaskModel.fromTask(task).copyWith(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, model);
    return model;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<Task?> getTaskById(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _tasks.firstWhere(
      (task) => task.id == taskId,
      orElse: () => throw StateError('Task not found'),
    );
  }

  @override
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? sortBy,
    String? order,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    var results = _tasks.toList();

    if (status != null) {
      results = results.where((task) => task.status.value == status).toList();
    }
    if (priority != null) {
      results = results.where((task) => task.priority.value == priority).toList();
    }

    if (sortBy != null) {
      results.sort((first, second) {
        switch (sortBy) {
          case 'deadline':
            return first.deadline.compareTo(second.deadline);
          case 'created_at':
            return first.createdAt.compareTo(second.createdAt);
          default:
            return 0;
        }
      });
      if (order == 'desc') {
        results = results.reversed.toList();
      }
    }

    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, results.length);
    return results.sublist(startIndex, endIndex);
  }

  @override
  Future<Task> updateTask(Task task) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      throw StateError('Task not found.');
    }

    final model = TaskModel.fromTask(task);
    _tasks[index] = model;
    return model;
  }
}
