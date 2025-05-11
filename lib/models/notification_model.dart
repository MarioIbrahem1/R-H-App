import 'package:flutter/foundation.dart';

enum NotificationType {
  helpRequest,
  updateAvailable,
  systemMessage,
  other,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _getNotificationType(json['type']),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      data: json['data'] ?? {},
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': describeEnum(type),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  static NotificationType _getNotificationType(String? type) {
    if (type == null) return NotificationType.other;
    
    switch (type.toLowerCase()) {
      case 'help_request':
        return NotificationType.helpRequest;
      case 'update_available':
        return NotificationType.updateAvailable;
      case 'system_message':
        return NotificationType.systemMessage;
      default:
        return NotificationType.other;
    }
  }

  // تحويل من نوع HelpRequest إلى NotificationModel
  static NotificationModel fromHelpRequest(Map<String, dynamic> helpRequestData) {
    final String requestId = helpRequestData['requestId'] ?? '';
    final String senderName = helpRequestData['senderName'] ?? '';
    
    return NotificationModel(
      id: requestId,
      title: 'طلب مساعدة',
      message: 'تلقيت طلب مساعدة من $senderName',
      type: NotificationType.helpRequest,
      timestamp: helpRequestData['timestamp'] is String
          ? DateTime.parse(helpRequestData['timestamp'])
          : DateTime.now(),
      data: helpRequestData,
      isRead: false,
    );
  }
}
