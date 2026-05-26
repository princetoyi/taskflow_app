import '../models/task_model.dart';

class TaskRepository {
  Future<void> addTask(TaskModel task) async {
    throw UnimplementedError('TaskRepository.addTask is not implemented.');
  }

  Future<void> updateTask(TaskModel task) async {
    throw UnimplementedError('TaskRepository.updateTask is not implemented.');
  }

  Future<void> deleteTask(String taskId) async {
    throw UnimplementedError('TaskRepository.deleteTask is not implemented.');
  }

  Stream<List<TaskModel>> getUserTasks(String userId) {
    return const Stream.empty();
  }
}
