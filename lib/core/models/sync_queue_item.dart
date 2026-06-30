import 'dart:convert';
import 'package:hive/hive.dart';

enum SyncOperation { create, update, delete }

class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final String taskId;
  final String taskPayloadJson;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.taskId,
    required this.taskPayloadJson,
  });

  Map<String, dynamic> get taskPayload {
    return jsonDecode(taskPayloadJson) as Map<String, dynamic>;
  }

  factory SyncQueueItem.create(dynamic task) {
    return SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: SyncOperation.create,
      taskId: task.id,
      taskPayloadJson: jsonEncode(task.toJson()),
    );
  }

  factory SyncQueueItem.update(dynamic task) {
    return SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: SyncOperation.update,
      taskId: task.id,
      taskPayloadJson: jsonEncode(task.toJson()),
    );
  }

  factory SyncQueueItem.delete(String taskId) {
    return SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: SyncOperation.delete,
      taskId: taskId,
      taskPayloadJson: jsonEncode({'id': taskId}),
    );
  }
}

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 1;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final id = reader.readString();
    final operationIndex = reader.readInt();
    final taskId = reader.readString();
    final taskPayloadJson = reader.readString();
    return SyncQueueItem(
      id: id,
      operation: SyncOperation.values[operationIndex],
      taskId: taskId,
      taskPayloadJson: taskPayloadJson,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.operation.index);
    writer.writeString(obj.taskId);
    writer.writeString(obj.taskPayloadJson);
  }
}
