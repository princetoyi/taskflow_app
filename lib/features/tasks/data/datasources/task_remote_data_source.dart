import 'package:dio/dio.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final ApiClient apiClient;

  TaskRemoteDataSource({required this.apiClient});

  Future<List<TaskModel>> fetchTasks({
    String? status,
    String? priority,
    String? sortBy,
    String? order,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final rawData = await apiClient.get<dynamic>(
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
      final responseData = await apiClient.post<dynamic>(
        '/tasks',
        data: task.toCreateJson(),
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(responseData));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final responseData = await apiClient.put<dynamic>(
        '/tasks/${task.id}',
        data: task.toUpdateJson(),
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(responseData));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await apiClient.delete<dynamic>('/tasks/$taskId');
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<TaskModel> fetchTaskById(String taskId) async {
    try {
      final responseData = await apiClient.get<dynamic>('/tasks/$taskId');
      return TaskModel.fromJson(Map<String, dynamic>.from(responseData));
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    final message = error.response?.data?['detail']?.toString() ?? error.message ?? 'Task API unavailable.';
    return AppException(message);
  }
}
