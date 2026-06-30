import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow_app/features/tasks/domain/entities/task_status.dart';
import 'package:taskflow_app/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_event.dart';
import 'package:taskflow_app/features/tasks/presentation/bloc/task_state.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> _tasks;

  FakeTaskRepository([List<Task>? initialTasks]) : _tasks = initialTasks ?? [];

  @override
  Future<Task> createTask(Task task) async {
    _tasks.insert(0, task);
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<Task?> getTaskById(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    return index >= 0 ? _tasks[index] : null;
  }

  @override
  Future<List<Task>> getTasks({String? status, String? priority, String? sortBy, String? order, int page = 1, int pageSize = 20}) async {
    return List<Task>.from(_tasks);
  }

  @override
  Future<Task> updateTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      throw StateError('Task not found.');
    }
    _tasks[index] = task;
    return task;
  }
}

void main() {
  group('TaskBloc', () {
    late FakeTaskRepository repository;
    late TaskBloc bloc;

    setUp(() {
      repository = FakeTaskRepository();
      bloc = TaskBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with TaskInitial', () {
      expect(bloc.state, const TaskInitial());
    });

    test('LoadTasks emits loading then loaded with tasks', () async {
      final task = Task(
        id: 'task-1',
        userId: 'user-1',
        title: 'Test Task',
        description: 'Test description',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        deadline: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );
      repository = FakeTaskRepository([task]);
      bloc = TaskBloc(repository);

      final expectedStates = <TaskState>[
        const TaskLoading(),
        TaskLoaded([task]),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadTasks());
      await future;
    });

    test('CreateTask emits loading then loaded with created task', () async {
      final task = Task(
        id: 'task-2',
        userId: 'user-1',
        title: 'New Task',
        description: 'Create test',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        deadline: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      final expectedStates = <dynamic>[
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks, 'tasks', [task]),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(CreateTask(task));
      await future;
    });

    test('ToggleTaskStatus applies optimistic update and then saves', () async {
      final task = Task(
        id: 'task-3',
        userId: 'user-1',
        title: 'Toggle Task',
        description: 'Toggle status test',
        status: TaskStatus.pending,
        priority: TaskPriority.low,
        deadline: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );
      repository = FakeTaskRepository([task]);
      bloc = TaskBloc(repository);

      final updatedTask = Task(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        status: TaskStatus.completed,
        priority: task.priority,
        deadline: task.deadline,
        createdAt: task.createdAt,
      );

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<TaskLoaded>().having((s) => s.tasks.first.status, 'final status', TaskStatus.completed)),
      );

      bloc.add(const LoadTasks());
      await bloc.stream.firstWhere((state) => state is TaskLoaded);
      bloc.add(UpdateTask(updatedTask));
      await future;
    });
  });
}
