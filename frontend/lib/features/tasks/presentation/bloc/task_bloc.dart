import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
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
    on<ToggleTaskStatus>(_onToggleTaskStatus);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(const TaskLoading());
    try {
      final tasks = await taskRepository.getTasks();
      emit(TaskLoaded(tasks));
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

  Future<void> _onToggleTaskStatus(ToggleTaskStatus event, Emitter<TaskState> emit) async {
    final currentTasks = state is TaskLoaded ? (state as TaskLoaded).tasks : <Task>[];
    final toggledTask = _toggleStatus(event.task);
    final updatedTasks = _replaceTask(currentTasks, toggledTask);
    emit(TaskLoaded(updatedTasks));

    try {
      final saved = await taskRepository.updateTask(toggledTask);
      emit(TaskLoaded(_replaceTask(updatedTasks, saved)));
    } catch (error) {
      emit(TaskError(_mapError(error)));
      emit(TaskLoaded(currentTasks));
    }
  }

  Task _toggleStatus(Task task) {
    final status = task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed;
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: status,
      priority: task.priority,
      deadline: task.deadline,
      createdAt: task.createdAt,
    );
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
