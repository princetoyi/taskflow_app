import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc(this.taskRepository) : super(const TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskLoading());
    try {
      final tasks = await taskRepository.getTasks(
        status: event.status,
        priority: event.priority,
        sortBy: event.sortBy,
        order: event.order,
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(TaskLoaded(
        tasks,
        status: event.status,
        priority: event.priority,
        sortBy: event.sortBy,
        order: event.order,
        page: event.page,
        pageSize: event.pageSize,
      ));
    } catch (error) {
      emit(TaskError(_mapError(error)));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    final currentTasks = state is TaskLoaded ? (state as TaskLoaded).tasks : <Task>[];
    emit(const TaskLoading());
    try {
      final created = await taskRepository.createTask(event.task);
      emit(TaskLoaded([created, ...currentTasks]));
    } catch (error) {
      emit(TaskError(_mapError(error)));
      emit(TaskLoaded(currentTasks));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    final currentTasks = state is TaskLoaded ? (state as TaskLoaded).tasks : <Task>[];
    final updatedTasks = currentTasks.map((task) {
      return task.id == event.task.id ? event.task : task;
    }).toList();
    emit(TaskLoaded(updatedTasks));
    try {
      final updated = await taskRepository.updateTask(event.task);
      emit(TaskLoaded(_replaceTask(updatedTasks, updated)));
    } catch (error) {
      emit(TaskError(_mapError(error)));
      emit(TaskLoaded(currentTasks));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    final currentTasks = state is TaskLoaded ? (state as TaskLoaded).tasks : <Task>[];
    final updatedTasks = currentTasks.where((task) => task.id != event.taskId).toList();
    emit(TaskLoaded(updatedTasks));
    try {
      await taskRepository.deleteTask(event.taskId);
    } catch (error) {
      emit(TaskError(_mapError(error)));
      emit(TaskLoaded(currentTasks));
    }
  }

  List<Task> _replaceTask(List<Task> tasks, Task newTask) {
    return tasks
        .map((task) => task.id == newTask.id ? newTask : task)
        .toList();
  }

  String _mapError(Object error) {
    return error is Exception ? error.toString() : 'Unable to update tasks. Please try again.';
  }
}
