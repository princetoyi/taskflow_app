import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  Future<Task> createTask(Task task) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('Unable to create task while offline.');
    }
    return remoteDataSource.createTask(TaskModel.fromTask(task));
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('Unable to delete task while offline.');
    }
    return remoteDataSource.deleteTask(taskId);
  }

  @override
  Future<Task?> getTaskById(String taskId) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('Unable to load task details while offline.');
    }
    return await remoteDataSource.fetchTaskById(taskId);
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
    if (!await connectivityService.hasConnection) {
      throw AppException('Unable to load tasks while offline.');
    }

    return remoteDataSource.fetchTasks(
      status: status,
      priority: priority,
      sortBy: sortBy,
      order: order,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (!await connectivityService.hasConnection) {
      throw AppException('Unable to update task while offline.');
    }
    return remoteDataSource.updateTask(TaskModel.fromTask(task));
  }
}
