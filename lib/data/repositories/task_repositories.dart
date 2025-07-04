import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow/data/queue/task_queue.dart';
import 'package:flow/models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final String _userId;
  final TaskQueue _taskQueue;

  TaskRepository({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _taskQueue = TaskQueue(
          processor: (task) async {
            try {
              final firestore = FirebaseFirestore.instance;
              final userTasksRef =
                  firestore.collection('users').doc(userId).collection('tasks');

              await userTasksRef.doc(task.id).set(task.toJson());
              return true;
            } catch (e) {
              return false;
            }
          },
        );

  CollectionReference<Map<String, dynamic>> get _userTasksCollection =>
      _firestore.collection('users').doc(_userId).collection('tasks');

  Future<void> addTask(Task task) async {
    _taskQueue.addTask(task);
  }

  Stream<List<Task>> getTasks() {
    return _userTasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList());
  }

  Stream<Task> onTaskUploaded() => _taskQueue.onTaskProcessed;

  Stream<Task> onTaskFailed() => _taskQueue.onTaskFailed;

  Stream<Task> onTaskAdded() => _taskQueue.onTaskAdded;

  void dispose() {
    _taskQueue.dispose();
  }
}
