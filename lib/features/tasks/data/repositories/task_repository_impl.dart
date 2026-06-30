import '../../../../core/errors/app_exception.dart';
import '../../../../core/local/sync_queue_datasource.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../local/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final TaskLocalDataSource localDataSource;
  final SyncQueueDataSource syncQueueDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
    required this.localDataSource,
    required this.syncQueueDataSource,
  });

  @override
  Future<Task> createTask(Task task) async {
    final model = TaskModel.fromTask(task);
    if (await connectivityService.hasConnection) {
      final created = await remoteDataSource.createTask(model);
      await localDataSource.cacheTask(created);
      return created;
    }

    await localDataSource.cacheTask(model);
    await syncQueueDataSource.enqueueCreate(model);
    return model;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (await connectivityService.hasConnection) {
      await remoteDataSource.deleteTask(taskId);
      await localDataSource.deleteCachedTask(taskId);
      return;
    }

    await localDataSource.deleteCachedTask(taskId);
    await syncQueueDataSource.enqueueDelete(taskId);
  }

  @override
  Future<Task?> getTaskById(String taskId) async {
    if (await connectivityService.hasConnection) {
      try {
        final task = await remoteDataSource.fetchTaskById(taskId);
        await localDataSource.cacheTask(TaskModel.fromTask(task));
        return task;
      } catch (_) {
        return await localDataSource.getCachedTask(taskId);
      }
    }

    return await localDataSource.getCachedTask(taskId);
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
    if (await connectivityService.hasConnection) {
      try {
        final tasks = await remoteDataSource.fetchTasks(
          status: status,
          priority: priority,
          sortBy: sortBy,
          order: order,
          page: page,
          pageSize: pageSize,
        );
        await localDataSource.cacheTasks(tasks);
        return tasks;
      } catch (error) {
        final cached = await localDataSource.getCachedTasks();
        if (cached.isNotEmpty) return cached;
        throw AppException('Unable to load tasks. Please try again.');
      }
    }

    return await localDataSource.getCachedTasks();
  }

  @override
  Future<Task> updateTask(Task task) async {
    final model = TaskModel.fromTask(task);
    if (await connectivityService.hasConnection) {
      final updated = await remoteDataSource.updateTask(model);
      await localDataSource.cacheTask(updated);
      return updated;
    }

    await localDataSource.cacheTask(model);
    await syncQueueDataSource.enqueueUpdate(model);
    return model;
  }
}
