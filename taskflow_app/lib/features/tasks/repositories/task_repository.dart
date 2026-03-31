import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'tasks';

  Future<void> addTask(TaskModel task) async {
    await _firestore.collection(collectionPath).add(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestore.collection(collectionPath).doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(collectionPath).doc(taskId).delete();
  }

  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
