import 'dart:async';

import 'package:flow/bloc/auth/auth_bloc.dart';
import 'package:flow/bloc/auth/auth_state.dart';
import 'package:flow/bloc/task/task_bloc.dart';
import 'package:flow/data/repositories/task_repositories.dart';
import 'package:flow/ui/screens/add_task_screen.dart';
import 'package:flow/ui/screens/dashboard_screen.dart';
import 'package:flow/ui/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthBloc authBloc;
  // Track the TaskBloc instance to share between routes
  TaskBloc? _taskBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // If the user is not logged in and is not on the login page,
      // redirect to the login page.
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If the user is logged in and is on the login page,
      // redirect to the dashboard.
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final authState = authBloc.state;
          if (authState is AuthAuthenticated) {
            // Create a single TaskBloc instance to share
            _taskBloc ??= TaskBloc(
              taskRepository: TaskRepository(
                userId: authState.user.uid,
              ),
            );

            return BlocProvider.value(
              value: _taskBloc!,
              child: const DashboardScreen(),
            );
          }
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) {
          // Use the same TaskBloc instance for the AddTaskScreen
          if (_taskBloc == null) {
            // If somehow the TaskBloc is null, redirect to dashboard first
            return const LoginScreen(); // This will get redirected
          }

          return BlocProvider.value(
            value: _taskBloc!,
            child: const AddTaskScreen(),
          );
        },
      ),
    ],
  );

  // Make sure to dispose TaskBloc when router is disposed
  void dispose() {
    _taskBloc?.close();
    _taskBloc = null;
  }
}

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
