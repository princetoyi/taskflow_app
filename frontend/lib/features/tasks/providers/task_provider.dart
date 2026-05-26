import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository = TaskRepository();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> addTask({
    required String title,
    required String description,
    required String userId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final task = TaskModel(
        id: '', // Firestore auto-generates this, handled by add() map structure normally
        title: title,
        description: description,
        createdAt: DateTime.now(),
        userId: userId,
      );
      await _repository.addTask(task);
    } catch (e) {
      debugPrint("Error adding task: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    try {
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      await _repository.updateTask(updated);
    } catch (e) {
      debugPrint("Error toggling task: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
    } catch (e) {
      debugPrint("Error deleting task: $e");
    }
  }

  Stream<List<TaskModel>> getUserTasksStream(String userId) {
    return _repository.getUserTasks(userId);
  }
}
