import 'package:hive/hive.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';

class TaskHiveModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int deadline;
  final int createdAt;

  TaskHiveModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.createdAt,
  });

  factory TaskHiveModel.fromTask(Task task) {
    return TaskHiveModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      status: task.status.value,
      priority: task.priority.value,
      deadline: task.deadline.millisecondsSinceEpoch,
      createdAt: task.createdAt.millisecondsSinceEpoch,
    );
  }

  Task toTask() {
    return Task(
      id: id,
      userId: userId,
      title: title,
      description: description,
      status: TaskStatus.fromValue(status),
      priority: TaskPriority.fromValue(priority),
      deadline: DateTime.fromMillisecondsSinceEpoch(deadline),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }
}

class TaskHiveModelAdapter extends TypeAdapter<TaskHiveModel> {
  @override
  final int typeId = 0;

  @override
  TaskHiveModel read(BinaryReader reader) {
    return TaskHiveModel(
      id: reader.readString(),
      userId: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      status: reader.readString(),
      priority: reader.readString(),
      deadline: reader.readInt(),
      createdAt: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskHiveModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeString(obj.status);
    writer.writeString(obj.priority);
    writer.writeInt(obj.deadline);
    writer.writeInt(obj.createdAt);
  }
}
