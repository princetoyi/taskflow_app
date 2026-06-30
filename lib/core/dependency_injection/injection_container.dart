import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../network/api_service.dart';
import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../services/sync_service.dart';
import '../local/sync_queue_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/data/datasources/user_remote_data_source.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/settings/presentation/bloc/theme_bloc.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/data/local/task_local_datasource.dart';
import '../../features/tasks/data/models/task_hive_model.dart';
import '../../features/tasks/data/repositories/mock_task_repository.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../../features/settings/data/datasources/theme_remote_data_source.dart';
import '../../features/settings/data/repositories/theme_repository.dart';
import '../../core/models/sync_queue_item.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InjectionContainer {
  static final GetIt locator = GetIt.instance;

  static Future<void> init() async {
    // ============ Core Services ============
    locator.registerLazySingleton<StorageService>(() => StorageService());
    locator.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
    locator.registerLazySingleton<LoggerService>(() => LoggerService());
    
    // ============ Network & API ============
    locator.registerLazySingleton<ApiService>(
      () => ApiService(storageService: locator<StorageService>()),
    );
    
    // High-level API client wrapper for easier usage
    locator.registerLazySingleton<ApiClient>(
      () => ApiClient(apiService: locator<ApiService>()),
    );
    
    // ============ Authentication ============
    locator.registerLazySingleton<AuthService>(() => AuthService());
    
    locator.registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        authService: locator<AuthService>(),
        apiClient: locator<ApiClient>(),
        storageService: locator<StorageService>(),
        connectivityService: locator<ConnectivityService>(),
      ),
    );
    
    // ============ User Management ============
    locator.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSource(apiClient: locator<ApiClient>()),
    );
    
    locator.registerLazySingleton<UserRepository>(
      () => UserRepository(
        remoteDataSource: locator<UserRemoteDataSource>(),
        storageService: locator<StorageService>(),
        connectivityService: locator<ConnectivityService>(),
      ),
    );
    
    // ============ Task Management ============
    locator.registerLazySingleton<TaskRemoteDataSource>(
      () => TaskRemoteDataSource(apiClient: locator<ApiClient>()),
    );

    locator.registerLazySingleton<TaskLocalDataSource>(
      () => TaskLocalDataSource(
        taskBox: Hive.box<TaskHiveModel>('tasks'),
      ),
    );

    locator.registerLazySingleton<ThemeRemoteDataSource>(
      () => ThemeRemoteDataSource(apiClient: locator<ApiClient>()),
    );

    locator.registerLazySingleton<SyncQueueDataSource>(
      () => SyncQueueDataSource(
        queueBox: Hive.box<SyncQueueItem>('sync_queue'),
      ),
    );

    locator.registerLazySingleton<SyncService>(
      () => SyncService(
        connectivityService: locator<ConnectivityService>(),
        syncQueueDataSource: locator<SyncQueueDataSource>(),
        remoteDataSource: locator<TaskRemoteDataSource>(),
        localDataSource: locator<TaskLocalDataSource>(),
      ),
    );

    // ============ Notifications ============
    locator.registerLazySingleton<LocalNotificationService>(
      () => LocalNotificationService(),
    );
    
    locator.registerLazySingleton<NotificationService>(
      () => NotificationService(),
    );
    
    locator.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(apiClient: locator<ApiClient>()),
    );
    
    locator.registerLazySingleton<NotificationBloc>(
      () {
        final bloc = NotificationBloc(repository: locator<NotificationRepository>());
        bloc.add(const LoadNotifications());
        return bloc;
      },
    );

    // ============ Theme Persistence ============
    locator.registerLazySingleton<ThemeRepository>(
      () => ThemeRepository(
        remoteDataSource: locator<ThemeRemoteDataSource>(),
        storageService: locator<StorageService>(),
        connectivityService: locator<ConnectivityService>(),
      ),
    );

    locator.registerLazySingleton<ThemeBloc>(
      () => ThemeBloc(themeRepository: locator<ThemeRepository>()),
    );

    // ============ Task Repository (Real or Mock) ============
    final useReal = dotenv.env['USE_REAL_TASKS']?.toLowerCase() == 'true';

    locator.registerLazySingleton<TaskRepository>(
      () {
        if (useReal) {
          return TaskRepositoryImpl(
            remoteDataSource: locator<TaskRemoteDataSource>(),
            connectivityService: locator<ConnectivityService>(),
            localDataSource: locator<TaskLocalDataSource>(),
            syncQueueDataSource: locator<SyncQueueDataSource>(),
          );
        }
        return MockTaskRepository();
      },
    );

    // ============ BLoCs (State Management) ============
    locator.registerLazySingleton<AuthBloc>(
      () => AuthBloc(locator<AuthRepository>()),
    );
  }
}
