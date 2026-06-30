import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final String? status;
  final String? priority;
  final String? sortBy;
  final String? order;
  final int page;
  final int pageSize;
  final String? message;

  const TaskLoaded(
    this.tasks, {
    this.status,
    this.priority,
    this.sortBy,
    this.order,
    this.page = 1,
    this.pageSize = 20,
    this.message,
  });

  @override
  List<Object?> get props => [tasks, status, priority, sortBy, order, page, pageSize, message];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
