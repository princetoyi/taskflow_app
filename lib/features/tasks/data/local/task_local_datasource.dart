import 'package:hive/hive.dart';
import '../../domain/entities/task.dart';
import '../models/task_hive_model.dart';
import '../models/task_model.dart';

class TaskLocalDataSource {
  final Box<TaskHiveModel> taskBox;

  TaskLocalDataSource({required this.taskBox});

  Future<List<Task>> getCachedTasks() async {
    return taskBox.values.map((item) => item.toTask()).toList();
  }

  Future<Task?> getCachedTask(String taskId) async {
    final model = taskBox.get(taskId);
    return model?.toTask();
  }

  Future<void> cacheTasks(List<TaskModel> tasks) async {
    await taskBox.clear();
    for (final task in tasks) {
      await taskBox.put(task.id, TaskHiveModel.fromTask(task));
    }
  }

  Future<void> cacheTask(TaskModel task) async {
    await taskBox.put(task.id, TaskHiveModel.fromTask(task));
  }

  Future<void> deleteCachedTask(String id) async {
    await taskBox.delete(id);
  }
}
