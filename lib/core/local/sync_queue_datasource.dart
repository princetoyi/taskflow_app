import 'package:hive/hive.dart';
import '../models/sync_queue_item.dart';
import '../../features/tasks/data/models/task_model.dart';

class SyncQueueDataSource {
  final Box<SyncQueueItem> queueBox;

  SyncQueueDataSource({required this.queueBox});

  Future<List<SyncQueueItem>> getPendingItems() async {
    return queueBox.values.toList();
  }

  Future<void> enqueueCreate(TaskModel task) async {
    final item = SyncQueueItem.create(task);
    await queueBox.put(item.id, item);
  }

  Future<void> enqueueUpdate(TaskModel task) async {
    final item = SyncQueueItem.update(task);
    await queueBox.put(item.id, item);
  }

  Future<void> enqueueDelete(String taskId) async {
    final item = SyncQueueItem.delete(taskId);
    await queueBox.put(item.id, item);
  }

  Future<void> removeItem(String itemId) async {
    await queueBox.delete(itemId);
  }
}
