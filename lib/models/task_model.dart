import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TaskStatus {
  created,
  queued,
  uploaded,
  failed,
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final TaskStatus status;
  final int retryCount;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.status = TaskStatus.created,
    this.retryCount = 0,
  });

  factory Task.create({
    required String title,
    required String description,
  }) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      status: TaskStatus.created,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    TaskStatus? status,
    int? retryCount,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.toString(),
      'retryCount': retryCount,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      status: _parseStatus(json['status'] as String? ?? 'created'),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  static TaskStatus _parseStatus(String status) {
    switch (status) {
      case 'TaskStatus.created':
      case 'created':
        return TaskStatus.created;
      case 'TaskStatus.queued':
      case 'queued':
        return TaskStatus.queued;
      case 'TaskStatus.uploaded':
      case 'uploaded':
        return TaskStatus.uploaded;
      case 'TaskStatus.failed':
      case 'failed':
        return TaskStatus.failed;
      default:
        return TaskStatus.created;
    }
  }

  @override
  List<Object?> get props =>
      [id, title, description, createdAt, status, retryCount];
}
