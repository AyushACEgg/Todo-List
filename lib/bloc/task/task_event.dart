import 'package:equatable/equatable.dart';
import 'package:flow/models/task_model.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TasksRequested extends TaskEvent {
  const TasksRequested();
}

class TaskAdded extends TaskEvent {
  final String title;
  final String description;

  const TaskAdded({
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [title, description];
}

class TaskUpdated extends TaskEvent {
  final Task task;

  const TaskUpdated(this.task);

  @override
  List<Object?> get props => [task];
}
