import 'dart:async';

import 'package:flow/bloc/task/task_event.dart';
import 'package:flow/bloc/task/task_state.dart';
import 'package:flow/data/repositories/task_repositories.dart';
import 'package:flow/models/task_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<Task>? _taskAddedSubscription;
  StreamSubscription<Task>? _taskUploadedSubscription;
  StreamSubscription<Task>? _taskFailedSubscription;

  final List<Task> _queuedTasks = [];

  TaskBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TaskInitial()) {
    on<TasksRequested>(_onTasksRequested);
    on<TaskAdded>(_onTaskAdded);
    on<TaskUpdated>(_onTaskUpdated);
    on<_TasksLoadedEvent>(_onTasksLoadedEvent);
    on<_TasksErrorEvent>(_onTasksErrorEvent);
    on<_UpdateTasksEvent>(_onUpdateTasksEvent);
    // Add handlers for new events
    on<_TaskQueuedEvent>(_onTaskQueuedEvent);
    on<_TaskUploadedEvent>(_onTaskUploadedEvent);

    _taskAddedSubscription = _taskRepository.onTaskAdded().listen((task) {
      _queuedTasks.add(task);
      add(const _UpdateTasksEvent());
      add(_TaskQueuedEvent(task));
    });

    _taskUploadedSubscription = _taskRepository.onTaskUploaded().listen((task) {
      _updateQueuedTaskStatus(task);
      add(_TaskUploadedEvent(task));
    });

    _taskFailedSubscription = _taskRepository.onTaskFailed().listen((task) {
      _updateQueuedTaskStatus(task);
    });
  }

  void _onTasksRequested(
    TasksRequested event,
    Emitter<TaskState> emit,
  ) {
    emit(const TasksLoading());
    try {
      _tasksSubscription?.cancel();
      _tasksSubscription = _taskRepository.getTasks().listen(
        (tasks) {
          add(_TasksLoadedEvent(tasks));
        },
        onError: (error) {
          add(_TasksErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  void _onTasksLoadedEvent(
    _TasksLoadedEvent event,
    Emitter<TaskState> emit,
  ) {
    emit(TasksLoaded(tasks: event.tasks, queuedTasks: _queuedTasks));
  }

  void _onTasksErrorEvent(
    _TasksErrorEvent event,
    Emitter<TaskState> emit,
  ) {
    emit(TasksError(event.message));
  }

  Future<void> _onTaskAdded(
    TaskAdded event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final task = Task.create(
        title: event.title,
        description: event.description,
      );

      await _taskRepository.addTask(task);
      emit(const TaskAddedSuccess());
    } catch (e) {
      emit(TaskAddedError(e.toString()));
    }
  }

  void _onTaskUpdated(
    TaskUpdated event,
    Emitter<TaskState> emit,
  ) {
    final currentState = state;
    if (currentState is TasksLoaded) {
      try {
        final updatedQueuedTasks = currentState.queuedTasks.map((task) {
          if (task.id == event.task.id) {
            return event.task;
          }
          return task;
        }).toList();

        emit(currentState.copyWith(queuedTasks: updatedQueuedTasks));
      } catch (e) {
        emit(TasksError(e.toString()));
      }
    }
  }

  void _updateQueuedTaskStatus(Task updatedTask) {
    int index = _queuedTasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _queuedTasks[index] = updatedTask;
      add(const _UpdateTasksEvent());
    }
  }

  void _onUpdateTasksEvent(
    _UpdateTasksEvent event,
    Emitter<TaskState> emit,
  ) {
    final currentState = state;
    if (currentState is TasksLoaded) {
      emit(currentState.copyWith(queuedTasks: List.from(_queuedTasks)));
    }
  }

  // Handle queue event
  void _onTaskQueuedEvent(
    _TaskQueuedEvent event,
    Emitter<TaskState> emit,
  ) {
    emit(TaskQueued(event.task));
    // Return to the previous state to maintain UI consistency
    if (state is TasksLoaded) {
      emit((state as TasksLoaded));
    } else {
      emit(const TaskInitial());
    }
  }

  // Handle upload event
  void _onTaskUploadedEvent(
    _TaskUploadedEvent event,
    Emitter<TaskState> emit,
  ) {
    emit(TaskUploaded(event.task));
    if (state is TasksLoaded) {
      emit((state as TasksLoaded));
    } else {
      emit(const TaskInitial());
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _taskAddedSubscription?.cancel();
    _taskUploadedSubscription?.cancel();
    _taskFailedSubscription?.cancel();
    _taskRepository.dispose();
    return super.close();
  }
}

// Private events used internally by the bloc
class _TasksLoadedEvent extends TaskEvent {
  final List<Task> tasks;

  const _TasksLoadedEvent(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class _TasksErrorEvent extends TaskEvent {
  final String message;

  const _TasksErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class _UpdateTasksEvent extends TaskEvent {
  const _UpdateTasksEvent();
}

class _TaskQueuedEvent extends TaskEvent {
  final Task task;

  const _TaskQueuedEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class _TaskUploadedEvent extends TaskEvent {
  final Task task;

  const _TaskUploadedEvent(this.task);

  @override
  List<Object?> get props => [task];
}
