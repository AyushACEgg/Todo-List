import 'dart:async';
import 'dart:collection';

import 'package:flow/models/task_model.dart';

typedef TaskProcessor = Future<bool> Function(Task task);

class TaskQueue {
  final Queue<Task> _queue = Queue<Task>();
  final TaskProcessor _processor;
  final Duration _processDelay;
  final int _maxRetries;
  bool _isProcessing = false;

  final _taskAddedController = StreamController<Task>.broadcast();
  final _taskProcessedController = StreamController<Task>.broadcast();
  final _taskFailedController = StreamController<Task>.broadcast();

  Stream<Task> get onTaskAdded => _taskAddedController.stream;
  Stream<Task> get onTaskProcessed => _taskProcessedController.stream;
  Stream<Task> get onTaskFailed => _taskFailedController.stream;

  TaskQueue({
    required TaskProcessor processor,
    Duration processDelay = const Duration(seconds: 20),
    int maxRetries = 3,
  })  : _processor = processor,
        _processDelay = processDelay,
        _maxRetries = maxRetries;

  void addTask(Task task) {
    final queuedTask = task.copyWith(status: TaskStatus.queued);
    _queue.add(queuedTask);
    _taskAddedController.add(queuedTask);
    _startProcessing();
  }

  int get pendingTasksCount => _queue.length;

  bool get isProcessing => _isProcessing;

  Future<void> _startProcessing() async {
    if (_isProcessing) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.first;

      await Future.delayed(_processDelay);

      try {
        final success = await _processor(task);

        if (success) {
          _queue.removeFirst();
          final processedTask = task.copyWith(status: TaskStatus.uploaded);
          _taskProcessedController.add(processedTask);
        } else {
          if (task.retryCount < _maxRetries) {
            _queue.removeFirst();
            final retryTask = task.copyWith(
              retryCount: task.retryCount + 1,
              status: TaskStatus.queued,
            );
            _queue.add(retryTask);
          } else {
            _queue.removeFirst();
            final failedTask = task.copyWith(status: TaskStatus.failed);
            _taskFailedController.add(failedTask);
          }
        }
      } catch (e) {
        if (task.retryCount < _maxRetries) {
          _queue.removeFirst();
          final retryTask = task.copyWith(
            retryCount: task.retryCount + 1,
            status: TaskStatus.queued,
          );
          _queue.add(retryTask);
        } else {
          _queue.removeFirst();
          final failedTask = task.copyWith(status: TaskStatus.failed);
          _taskFailedController.add(failedTask);
        }
      }
    }

    _isProcessing = false;
  }

  void dispose() {
    _taskAddedController.close();
    _taskProcessedController.close();
    _taskFailedController.close();
  }
}
