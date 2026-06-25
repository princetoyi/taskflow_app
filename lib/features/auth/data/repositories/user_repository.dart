import '../../models/user_model.dart';
import '../datasources/user_remote_data_source.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/connectivity_service.dart';

/// Repository for user-related operations
/// 
/// Follows the clean architecture pattern:
/// - Abstracts API and local storage details
/// - Handles offline/online logic
/// - Provides data to the presentation layer via BLoC
class UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final StorageService storageService;
  final ConnectivityService connectivityService;

  const UserRepository({
    required this.remoteDataSource,
    required this.storageService,
    required this.connectivityService,
  });

  /// Gets the current user's profile from the backend
  /// 
  /// Returns: [UserModel] with user profile data
  /// Throws: [Exception] if user is offline or API error
  Future<UserModel> getCurrentUserProfile() async {
    try {
      // Always fetch fresh data from backend
      final userModel = await remoteDataSource.getCurrentUserProfile();
      
      // Cache the user data locally for offline reference
      // (Optional: implement caching in StorageService if needed)
      
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets a specific user by ID
  /// 
  /// Parameters:
  ///   - [userId]: The ID of the user to fetch
  /// 
  /// Returns: [UserModel] with user data
  /// Throws: [Exception] if user not found or offline
  Future<UserModel> getUserById(String userId) {
    return remoteDataSource.getUserById(userId);
  }

  /// Gets a list of users with optional filtering
  /// 
  /// Parameters:
  ///   - [role]: Optional filter by role
  ///   - [isActive]: Optional filter by active status
  ///   - [page]: Page number for pagination
  ///   - [pageSize]: Items per page
  /// 
  /// Returns: List of [UserModel]
  Future<List<UserModel>> getUsers({
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) {
    return remoteDataSource.getUsers(
      role: role,
      isActive: isActive,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Gets list of team members (typically employees for a manager)
  /// 
  /// Returns: List of [UserModel] representing team members
  Future<List<UserModel>> getTeamMembers({
    int page = 1,
    int pageSize = 50,
  }) {
    return remoteDataSource.getUsers(
      role: 'employee',
      isActive: true,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Updates the current user's profile
  /// 
  /// Parameters:
  ///   - [user]: Updated [UserModel]
  /// 
  /// Returns: Updated [UserModel]
  /// Throws: [Exception] if validation fails or offline
  Future<UserModel> updateProfile(UserModel user) async {
    final updatedUser = await remoteDataSource.updateProfile(user);
    
    // Cache updated user data if needed
    // await _cacheUserData(updatedUser);
    
    return updatedUser;
  }

  /// Updates a specific user (typically admin operation)
  /// 
  /// Parameters:
  ///   - [userId]: ID of user to update
  ///   - [user]: Updated user data
  /// 
  /// Returns: Updated [UserModel]
  Future<UserModel> updateUser(String userId, UserModel user) {
    return remoteDataSource.updateUser(userId, user);
  }

  /// Uploads or updates user's profile picture
  /// 
  /// Parameters:
  ///   - [imagePath]: Path to image file on device
  /// 
  /// Returns: Updated [UserModel] with new profile image URL
  /// Throws: [Exception] if upload fails
  Future<UserModel> uploadProfileImage(String imagePath) {
    return remoteDataSource.uploadProfileImage(imagePath);
  }

  /// Changes the current user's password
  /// 
  /// Parameters:
  ///   - [currentPassword]: Current password for verification
  ///   - [newPassword]: New password to set
  /// 
  /// Throws: [Exception] if current password is invalid or offline
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Deletes a user from the system (admin operation)
  /// 
  /// Parameters:
  ///   - [userId]: ID of user to delete
  /// 
  /// Throws: [Exception] if not authorized or user not found
  Future<void> deleteUser(String userId) {
    return remoteDataSource.deleteUser(userId);
  }

  /// Checks if the app is currently online
  /// 
  /// Returns: true if connected to internet
  Future<bool> isOnline() async {
    return await connectivityService.hasConnection;
  }
}
