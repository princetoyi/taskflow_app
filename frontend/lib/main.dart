import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_theme.dart';
import 'core/dependency_injection/injection_container.dart';
import 'services/firebase_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseService.initializeFirebase();
  await InjectionContainer.init();

  final authBloc = InjectionContainer.locator<AuthBloc>();
  final taskRepository = InjectionContainer.locator<TaskRepository>();

  authBloc.add(CheckAuthStatus());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TaskRepository>(create: (_) => taskRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider<TaskBloc>(
            create: (_) => TaskBloc(taskRepository)..add(const LoadTasks()),
          ),
        ],
        child: TaskFlowApp(authBloc: authBloc),
      ),
    ),
  );
}

class TaskFlowApp extends StatelessWidget {
  final AuthBloc authBloc;

  const TaskFlowApp({Key? key, required this.authBloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(authBloc: authBloc).router;

    return MaterialApp.router(
      title: 'TaskFlow',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

