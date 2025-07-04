import 'package:flow/bloc/auth/auth_bloc.dart';
import 'package:flow/bloc/auth/auth_event.dart';
import 'package:flow/bloc/auth/auth_state.dart';
import 'package:flow/bloc/task/task_bloc.dart';
import 'package:flow/bloc/task/task_event.dart';
import 'package:flow/bloc/task/task_state.dart';
import 'package:flow/ui/widget/task_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(const TasksRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const SignOutRequested());
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TaskBloc, TaskState>(
            listenWhen: (previous, current) => current is TaskQueued,
            listener: (context, state) {
              if (state is TaskQueued) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${state.task.title}" added to queue'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          BlocListener<TaskBloc, TaskState>(
            listenWhen: (previous, current) => current is TaskUploaded,
            listener: (context, state) {
              if (state is TaskUploaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Task "${state.task.title}" uploaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            const Divider(),
            Expanded(
              child: _buildTaskList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserInfo() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logged in as:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.user.email ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Task will be in queue for 20 sec',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      buildWhen: (previous, current) =>
          current is TasksLoading ||
          current is TasksLoaded ||
          current is TasksError,
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is TasksLoaded) {
          final allTasks = [...state.tasks];

          // Add queued tasks that aren't in Firestore yet
          for (final queuedTask in state.queuedTasks) {
            if (!allTasks.any((task) => task.id == queuedTask.id)) {
              allTasks.add(queuedTask);
            }
          }

          if (allTasks.isEmpty) {
            return const Center(
              child: Text(
                'No tasks yet. Add some tasks and Added tasks will be inn queue for 20 sec',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = allTasks[index];
              return TaskListItem(task: task);
            },
          );
        } else if (state is TasksError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskBloc>().add(const TasksRequested());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
