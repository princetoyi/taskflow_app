import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ThemeRemoteDataSource {
  final ApiClient apiClient;

  ThemeRemoteDataSource({required this.apiClient});

  Future<String> fetchTheme() async {
    try {
      final data = await apiClient.get<dynamic>('/users/preferences');
      if (data is Map<String, dynamic> && data['theme'] is String) {
        return data['theme'] as String;
      }
      return 'light';
    } on DioException {
      return 'light';
    }
  }

  Future<void> saveTheme(String theme) async {
    try {
      await apiClient.put('/users/preferences', data: {'theme': theme});
    } on DioException catch (e) {
      throw Exception('Failed to save theme: ${e.message}');
    }
  }
}
