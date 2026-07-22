import 'package:dio/dio.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/logger_service.dart';
import '../../models/user_model.dart';

/// Remote data source for user-related API calls
class UserRemoteDataSource {
  final ApiClient apiClient;

  const UserRemoteDataSource({required this.apiClient});

  /// Fetches the current user's profile
  /// 
  /// Returns: [UserModel] with full profile information
  /// Throws: [AppException] on API error
  Future<UserModel> getCurrentUserProfile() async {
    try {
      LoggerService.debug('Fetching current user profile');
      
      final response = await apiClient.get<dynamic>('/users/profile');
      
      if (response == null) {
        throw AppException('Empty response from server');
      }

      final userModel = UserModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      
      LoggerService.debug('User profile fetched successfully: ${userModel.email}');
      return userModel;
    } on DioException catch (error) {
      LoggerService.error('Failed to fetch user profile', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error fetching user profile', error);
      throw AppException('Failed to load user profile');
    }
  }

  /// Fetches a specific user by ID
  /// 
  /// Parameters:
  ///   - [userId]: The ID of the user to fetch
  /// 
  /// Returns: [UserModel] with user information
  /// Throws: [AppException] on API error
  Future<UserModel> getUserById(String userId) async {
    try {
      LoggerService.debug('Fetching user: $userId');
      
      final response = await apiClient.get<dynamic>('/users/$userId');
      
      if (response == null) {
        throw AppException('User not found');
      }

      return UserModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on DioException catch (error) {
      LoggerService.error('Failed to fetch user $userId', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error fetching user $userId', error);
      throw AppException('Failed to load user information');
    }
  }

  /// Fetches a list of users with optional filtering
  /// 
  /// Parameters:
  ///   - [role]: Optional filter by user role
  ///   - [isActive]: Optional filter by active status
  ///   - [page]: Page number for pagination (default: 1)
  ///   - [pageSize]: Number of results per page (default: 20)
  /// 
  /// Returns: List of [UserModel]
  /// Throws: [AppException] on API error
  Future<List<UserModel>> getUsers({
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      LoggerService.debug('Fetching users list (page: $page, size: $pageSize)');
      
      final response = await apiClient.get<dynamic>(
        '/users',
        queryParameters: {
          if (role != null) 'role': role,
          if (isActive != null) 'is_active': isActive,
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response == null) {
        return [];
      }

      // Handle both array and paginated response formats
      final rawData = response;
      final items = rawData is List
          ? rawData
          : rawData is Map<String, dynamic>
              ? rawData['items'] ?? rawData['results'] ?? []
              : [];

      final users = (items as List<dynamic>)
          .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      
      LoggerService.debug('Fetched ${users.length} users');
      return users;
    } on DioException catch (error) {
      LoggerService.error('Failed to fetch users list', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error fetching users', error);
      throw AppException('Failed to load users list');
    }
  }

  /// Updates the current user's profile
  /// 
  /// Parameters:
  ///   - [user]: The updated [UserModel]
  /// 
  /// Returns: Updated [UserModel]
  /// Throws: [AppException] on API error
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      LoggerService.debug('Updating user profile: ${user.email}');

      // The backend's self-service update endpoint expects snake_case keys
      // and only accepts these four fields — role/isActive intentionally
      // aren't here, since only an admin-scoped request can change those.
      final response = await apiClient.patch<dynamic>(
        '/users/profile',
        data: {
          if (user.displayName != null) 'display_name': user.displayName,
          if (user.firstName != null) 'first_name': user.firstName,
          if (user.lastName != null) 'last_name': user.lastName,
          if (user.phoneNumber != null) 'phone_number': user.phoneNumber,
        },
      );

      if (response == null) {
        throw AppException('Failed to update profile');
      }

      final updatedUser = UserModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      
      LoggerService.debug('User profile updated successfully');
      return updatedUser;
    } on DioException catch (error) {
      LoggerService.error('Failed to update user profile', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error updating profile', error);
      throw AppException('Failed to update profile');
    }
  }

  /// Updates a specific user (admin operation)
  /// 
  /// Parameters:
  ///   - [userId]: ID of user to update
  ///   - [user]: Updated user data
  /// 
  /// Returns: Updated [UserModel]
  /// Throws: [AppException] on API error
  Future<UserModel> updateUser(String userId, UserModel user) async {
    try {
      LoggerService.debug('Updating user: $userId');

      // Admin-scoped update — snake_case keys, matches UserAdminUpdateRequest
      // on the backend. role/is_active are only settable through this path.
      final response = await apiClient.patch<dynamic>(
        '/users/$userId',
        data: {
          if (user.displayName != null) 'display_name': user.displayName,
          if (user.firstName != null) 'first_name': user.firstName,
          if (user.lastName != null) 'last_name': user.lastName,
          if (user.phoneNumber != null) 'phone_number': user.phoneNumber,
          if (user.role != null) 'role': user.role!.name,
          'is_active': user.isActive,
        },
      );

      if (response == null) {
        throw AppException('Failed to update user');
      }

      return UserModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } on DioException catch (error) {
      LoggerService.error('Failed to update user $userId', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error updating user', error);
      throw AppException('Failed to update user');
    }
  }

  /// Uploads or updates user's profile picture
  /// 
  /// Parameters:
  ///   - [imagePath]: Path to the image file
  /// 
  /// Returns: [UserModel] with updated profile image URL
  /// Throws: [AppException] on API error
  Future<UserModel> uploadProfileImage(String imagePath) async {
    try {
      LoggerService.debug('Uploading profile image: $imagePath');
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await apiClient.post<dynamic>(
        '/users/profile/image',
        data: formData,
      );

      if (response == null) {
        throw AppException('Failed to upload image');
      }

      final updatedUser = UserModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      
      LoggerService.debug('Profile image uploaded successfully');
      return updatedUser;
    } on DioException catch (error) {
      LoggerService.error('Failed to upload profile image', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error uploading profile image', error);
      throw AppException('Failed to upload profile image');
    }
  }

  /// Changes the user's password
  /// 
  /// Parameters:
  ///   - [currentPassword]: Current password for verification
  ///   - [newPassword]: New password
  /// 
  /// Throws: [AppException] on API error or invalid credentials
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      LoggerService.debug('Changing password');
      
      await apiClient.post<dynamic>(
        '/users/profile/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      
      LoggerService.debug('Password changed successfully');
    } on DioException catch (error) {
      LoggerService.error('Failed to change password', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error changing password', error);
      throw AppException('Failed to change password');
    }
  }

  /// Deletes a user (admin operation)
  /// 
  /// Parameters:
  ///   - [userId]: ID of user to delete
  /// 
  /// Throws: [AppException] on API error
  Future<void> deleteUser(String userId) async {
    try {
      LoggerService.debug('Deleting user: $userId');
      
      await apiClient.delete<dynamic>('/users/$userId');
      
      LoggerService.debug('User deleted successfully');
    } on DioException catch (error) {
      LoggerService.error('Failed to delete user $userId', error);
      throw _mapDioException(error);
    } catch (error) {
      LoggerService.error('Unexpected error deleting user', error);
      throw AppException('Failed to delete user');
    }
  }

  /// Maps DioException to AppException
  static AppException _mapDioException(DioException error) {
    if (error.response?.statusCode == 401) {
      return AppException('Unauthorized. Please log in again.');
    }
    if (error.response?.statusCode == 403) {
      return AppException('You do not have permission to perform this action.');
    }
    if (error.response?.statusCode == 404) {
      return AppException('User not found.');
    }
    if (error.response?.statusCode == 422) {
      // Validation errors
      final message = error.response?.data?['detail']?.toString() ?? 
          'Invalid data provided';
      return AppException(message);
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return AppException('Request timed out. Please check your connection.');
    }
    if (error.type == DioExceptionType.unknown) {
      return AppException('Network error. Please try again.');
    }
    
    return AppException(
      error.error?.toString() ?? 'Failed to process request',
    );
  }
}
