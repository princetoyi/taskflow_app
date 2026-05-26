import 'package:dio/dio.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_service.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final ApiService apiService;

  TaskRemoteDataSource({required this.apiService});

  Future<List<TaskModel>> fetchTasks({
    String? status,
    String? priority,
    String? sortBy,
    String? order,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiService.client.get(
        '/tasks',
        queryParameters: {
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
          if (sortBy != null) 'sort_by': sortBy,
          if (order != null) 'order': order,
          'page': page,
          'page_size': pageSize,
        },
      );

      final rawData = response.data;
      final items = rawData is List
          ? rawData
          : rawData is Map<String, dynamic>
              ? rawData['items'] ?? []
              : [];

      return (items as List<dynamic>)
          .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await apiService.client.post(
        '/tasks',
        data: task.toJson(),
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await apiService.client.put(
        '/tasks/${task.id}',
        data: task.toJson(),
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await apiService.client.delete('/tasks/$taskId');
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<TaskModel> fetchTaskById(String taskId) async {
    try {
      final response = await apiService.client.get('/tasks/$taskId');
      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    final message = error.response?.data?['detail']?.toString() ?? error.message ?? 'Task API unavailable.';
    return AppException(message);
  }
}
