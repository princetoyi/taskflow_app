import 'dart:async';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/data/local/task_local_datasource.dart';
import '../local/sync_queue_datasource.dart';
import '../services/connectivity_service.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../models/sync_queue_item.dart';

class SyncService {
  final ConnectivityService connectivityService;
  final SyncQueueDataSource syncQueueDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  late final StreamSubscription<bool> _connectionSubscription;

  SyncService({
    required this.connectivityService,
    required this.syncQueueDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _connectionSubscription = connectivityService.isConnected.listen(
      (connected) {
        if (connected) {
          _processPendingQueue();
        }
      },
    );
  }

  Future<void> dispose() async {
    await _connectionSubscription.cancel();
  }

  Future<void> _processPendingQueue() async {
    final items = await syncQueueDataSource.getPendingItems();
    for (final item in items) {
      try {
        switch (item.operation) {
          case SyncOperation.create:
            final task = TaskModel.fromJson(item.taskPayload);
            final synced = await remoteDataSource.createTask(task);
            await localDataSource.cacheTask(synced);
            break;
          case SyncOperation.update:
            final task = TaskModel.fromJson(item.taskPayload);
            final synced = await remoteDataSource.updateTask(task);
            await localDataSource.cacheTask(synced);
            break;
          case SyncOperation.delete:
            await remoteDataSource.deleteTask(item.taskId);
            await localDataSource.deleteCachedTask(item.taskId);
            break;
        }
        await syncQueueDataSource.removeItem(item.id);
      } catch (_) {
        // leave item in queue and retry later
      }
    }
  }
}
