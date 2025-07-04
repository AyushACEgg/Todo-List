import 'package:equatable/equatable.dart';
import 'package:flow/models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TasksLoading extends TaskState {
  const TasksLoading();
}

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final List<Task> queuedTasks;

  const TasksLoaded({
    required this.tasks,
    required this.queuedTasks,
  });

  @override
  List<Object?> get props => [tasks, queuedTasks];

  TasksLoaded copyWith({
    List<Task>? tasks,
    List<Task>? queuedTasks,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      queuedTasks: queuedTasks ?? this.queuedTasks,
    );
  }
}

class TasksError extends TaskState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskAddedSuccess extends TaskState {
  const TaskAddedSuccess();
}

class TaskAddedError extends TaskState {
  final String message;

  const TaskAddedError(this.message);

  @override
  List<Object?> get props => [message];
}

// New states for task queue notifications
class TaskQueued extends TaskState {
  final Task task;

  const TaskQueued(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskUploaded extends TaskState {
  final Task task;

  const TaskUploaded(this.task);

  @override
  List<Object?> get props => [task];
}
