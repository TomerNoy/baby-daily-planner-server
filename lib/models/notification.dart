import 'package:mongo_dart/mongo_dart.dart';

class NotificationModel {
  final bool isPushOn;
  final ObjectId scheduledTaskId;
  final DateTime lastModified;

  NotificationModel({
    required this.isPushOn,
    required this.scheduledTaskId,
    required this.lastModified,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      isPushOn: map['isPushOn'] as bool,
      scheduledTaskId: map['scheduledTaskId'] as ObjectId,
      lastModified: DateTime.parse(map['lastModified']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPushOn': isPushOn,
      'scheduledTaskId': scheduledTaskId,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}
