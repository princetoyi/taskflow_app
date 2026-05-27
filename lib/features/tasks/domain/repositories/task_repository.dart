import '../entities/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? sortBy,
    String? order,
    int page = 1,
    int pageSize = 20,
  });

  Future<Task> createTask(Task task);

  Future<Task> updateTask(Task task);

  Future<void> deleteTask(String taskId);

  Future<Task?> getTaskById(String taskId);
}
