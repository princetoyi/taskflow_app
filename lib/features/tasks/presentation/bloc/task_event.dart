import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class FetchTasksRequested extends TaskEvent {
  final String? status;
  final String? priority;
  final String? sortBy;
  final String? order;
  final int page;
  final int pageSize;

  const FetchTasksRequested({
    this.status,
    this.priority,
    this.sortBy,
    this.order,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [status, priority, sortBy, order, page, pageSize];
}

// Legacy event name for backward compatibility
class LoadTasks extends FetchTasksRequested {
  const LoadTasks({
    String? status,
    String? priority,
    String? sortBy,
    String? order,
    int page = 1,
    int pageSize = 20,
  }) : super(
    status: status,
    priority: priority,
    sortBy: sortBy,
    order: order,
    page: page,
    pageSize: pageSize,
  );
}

class CreateTaskRequested extends TaskEvent {
  final Task task;

  const CreateTaskRequested(this.task);

  @override
  List<Object?> get props => [task];
}

// Legacy event name
class CreateTask extends CreateTaskRequested {
  const CreateTask(Task task) : super(task);
}

class UpdateTaskRequested extends TaskEvent {
  final Task task;

  const UpdateTaskRequested({required this.task});

  @override
  List<Object?> get props => [task];
}

// Legacy event name
class UpdateTask extends UpdateTaskRequested {
  const UpdateTask(Task task) : super(task: task);
}

class DeleteTaskRequested extends TaskEvent {
  final String taskId;

  const DeleteTaskRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

// Legacy event name
class DeleteTask extends DeleteTaskRequested {
  const DeleteTask(String taskId) : super(taskId);
}
