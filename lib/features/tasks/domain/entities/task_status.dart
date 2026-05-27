enum TaskStatus { pending, completed }

extension TaskStatusX on TaskStatus {
  String get value => toString().split('.').last;

  bool get isCompleted => this == TaskStatus.completed;

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}
