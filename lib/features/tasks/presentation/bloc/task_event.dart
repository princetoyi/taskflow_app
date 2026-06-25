import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  final String? status;
  final String? priority;
  final String? sortBy;
  final String? order;
  final int page;
  final int pageSize;

  const LoadTasks({
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

class CreateTask extends TaskEvent {
  final Task task;

  const CreateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TaskEvent {
  final Task task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;

  const DeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
