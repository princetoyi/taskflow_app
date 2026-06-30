import 'package:equatable/equatable.dart';

enum NotificationType {
  taskAssigned,
  taskCompleted,
  progressUpdate,
  blockerFlagged,
  overdueAlert,
  morningReminder,
  eveningCheckIn,
}

/// Notification model for data layer
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLink;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.deepLink,
    this.metadata,
  });

  /// Create copy with modifications
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? deepLink,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deepLink: deepLink ?? this.deepLink,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert from JSON (Firebase)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      type: _parseNotificationType(
        json['type'] as String? ?? json['notification_type'] as String?,
      ),
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      deepLink: json['deepLink'] as String? ?? json['deep_link'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON (for sending to backend)
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'deepLink': deepLink,
        'metadata': metadata,
      };

  /// Parse notification type from string
  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.taskAssigned;

    try {
      return NotificationType.values.firstWhere(
        (type) => type.toString().split('.').last == typeString,
        orElse: () => NotificationType.taskAssigned,
      );
    } catch (e) {
      return NotificationType.taskAssigned;
    }
  }

  /// Get notification type display name
  String get typeDisplayName {
    switch (type) {
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.progressUpdate:
        return 'Progress Update';
      case NotificationType.blockerFlagged:
        return 'Blocker Flagged';
      case NotificationType.overdueAlert:
        return 'Overdue Alert';
      case NotificationType.morningReminder:
        return 'Morning Reminder';
      case NotificationType.eveningCheckIn:
        return 'Evening Check-In';
    }
  }

  /// Get notification type badge color
  String get typeColorHex {
    switch (type) {
      case NotificationType.taskAssigned:
        return '#FFFBEB'; // Amber background
      case NotificationType.taskCompleted:
        return '#ECFDF5'; // Green background
      case NotificationType.progressUpdate:
        return '#EFF6FF'; // Blue background
      case NotificationType.blockerFlagged:
        return '#F5F3FF'; // Purple background
      case NotificationType.overdueAlert:
        return '#FEF2F2'; // Red background
      case NotificationType.morningReminder:
        return '#F3F4F6'; // Gray background
      case NotificationType.eveningCheckIn:
        return '#EFF6FF'; // Blue background
    }
  }

  /// Get notification type text color
  String get typeColorTextHex {
    switch (type) {
      case NotificationType.taskAssigned:
        return '#B45309'; // Amber text
      case NotificationType.taskCompleted:
        return '#047857'; // Green text
      case NotificationType.progressUpdate:
        return '#2563EB'; // Blue text
      case NotificationType.blockerFlagged:
        return '#7C3AED'; // Purple text
      case NotificationType.overdueAlert:
        return '#B91C1C'; // Red text
      case NotificationType.morningReminder:
        return '#6B7280'; // Gray text
      case NotificationType.eveningCheckIn:
        return '#2563EB'; // Blue text
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        type,
        isRead,
        createdAt,
        deepLink,
        metadata,
      ];
}
