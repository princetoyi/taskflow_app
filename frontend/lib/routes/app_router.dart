import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/dashboard_screen.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/screens/create_task_screen.dart';
import '../features/tasks/screens/task_detail_screen.dart';
import '../features/tasks/domain/entities/task.dart';
import 'app_routes.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirectLogic,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Page not found', textAlign: TextAlign.center),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskCreate,
        builder: (context, state) {
          final task = state.extra as Task?;
          return CreateTaskScreen(initialTask: task);
        },
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          final task = state.extra as Task?;
          return TaskDetailScreen(taskId: taskId, initialTask: task);
        },
      ),
    ],
  );

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final isAuthenticated = authBloc.state is Authenticated;
    final isLoginOrSignup = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.signup;

    if (!isAuthenticated && !isLoginOrSignup) {
      return AppRoutes.login;
    }

    if (isAuthenticated && isLoginOrSignup) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}
