import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskflow_app/services/firebase_service.dart';
import 'core/constants/app_theme.dart';
import 'core/dependency_injection/injection_container.dart';
import 'core/network/api_client.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/settings/presentation/bloc/theme_bloc.dart';
import 'features/settings/presentation/bloc/theme_event.dart';
import 'features/settings/presentation/bloc/theme_state.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/tasks/data/models/task_hive_model.dart';
import 'core/models/sync_queue_item.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseService.initializeFirebase();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskHiveModelAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  await Hive.openBox<TaskHiveModel>('tasks');
  await Hive.openBox<SyncQueueItem>('sync_queue');
  await InjectionContainer.init();

  // Eagerly instantiate the sync service so queued offline actions are processed
  // automatically when connectivity is restored.
  InjectionContainer.locator<SyncService>();

  final authBloc = InjectionContainer.locator<AuthBloc>();
  final taskRepository = InjectionContainer.locator<TaskRepository>();
  final themeBloc = InjectionContainer.locator<ThemeBloc>();
  final notificationService = InjectionContainer.locator<NotificationService>();
  final localNotificationService = InjectionContainer.locator<LocalNotificationService>();
  final notificationBloc = InjectionContainer.locator<NotificationBloc>();
  final profileBloc = InjectionContainer.locator<ProfileBloc>();

  final appRouter = AppRouter(authBloc: authBloc);
  final router = appRouter.router;

  authBloc.add(CheckAuthStatus());
  themeBloc.add(const LoadTheme());

  await localNotificationService.initialize();
  await notificationService.initialize(
    apiClient: InjectionContainer.locator<ApiClient>(),
    storageService: InjectionContainer.locator<StorageService>(),
    localNotificationService: localNotificationService,
    onNotificationTap: (data) {
      try {
        final deepLink = data['deepLink'] as String?;
        final taskId = data['task_id'] as String? ?? data['taskId'] as String?;
        final target = deepLink?.isNotEmpty == true
            ? deepLink
            : taskId != null
                ? AppRoutes.taskDetail.replaceFirst(':id', taskId)
                : null;

        if (target != null) {
          router.go(target);
        }
      } catch (_) {
        // Ignore navigation failures from background payloads
      }
    },
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TaskRepository>(create: (_) => taskRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: themeBloc),
          BlocProvider.value(value: notificationBloc),
          BlocProvider.value(value: profileBloc),
          BlocProvider<TaskBloc>(
            create: (_) => TaskBloc(taskRepository)..add(const FetchTasksRequested()),
          ),
        ],
        child: TaskFlowApp(authBloc: authBloc, router: router),
      ),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  final AuthBloc authBloc;
  final GoRouter router;

  const TaskFlowApp({Key? key, required this.authBloc, required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final themeMode = themeState is ThemeLoaded ? themeState.mode : ThemeMode.light;
        return MaterialApp.router(
          title: 'TaskFlow',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

