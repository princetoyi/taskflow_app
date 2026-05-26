import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../network/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/logger_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/data/repositories/mock_task_repository.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';

class InjectionContainer {
  static final GetIt locator = GetIt.instance;

  static Future<void> init() async {
    locator.registerLazySingleton<StorageService>(() => StorageService());
    locator.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
    locator.registerLazySingleton<LoggerService>(() => LoggerService());
    locator.registerLazySingleton<ApiService>(() => ApiService(storageService: locator<StorageService>()));
    locator.registerLazySingleton<AuthService>(() => AuthService());
    locator.registerLazySingleton<AuthRepository>(() => AuthRepository(
          authService: locator<AuthService>(),
          apiService: locator<ApiService>(),
          storageService: locator<StorageService>(),
          connectivityService: locator<ConnectivityService>(),
        ));
    locator.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSource(apiService: locator<ApiService>()));

    // Allow switching between the mock repository and the real API-backed
    // repository via the environment variable `USE_REAL_TASKS` (default: false).
    final useReal = dotenv.env['USE_REAL_TASKS']?.toLowerCase() == 'true';

    locator.registerLazySingleton<TaskRepository>(() {
      if (useReal) {
        return TaskRepositoryImpl(
          remoteDataSource: locator<TaskRemoteDataSource>(),
          connectivityService: locator<ConnectivityService>(),
        );
      }
      return MockTaskRepository();
    });
    locator.registerLazySingleton<AuthBloc>(() => AuthBloc(locator<AuthRepository>()));
  }
}
