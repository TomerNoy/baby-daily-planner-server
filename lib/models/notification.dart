import 'package:mongo_dart/mongo_dart.dart';
import 'package:myserver/services/services.dart';

class NotificationModel {
  ObjectId scheduledTaskId;
  DateTime lastModified;
  bool isPushOn;

  NotificationModel({
    DateTime? lastModified,
    ObjectId? scheduledTaskId,
    required this.isPushOn,
  })  : lastModified = lastModified ?? DateTime.now(),
        scheduledTaskId = scheduledTaskId ?? ObjectId();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final scheduledTaskId = switch (map['scheduledTaskId']) {
      ObjectId idData => idData,
      String idData => ObjectId.fromHexString(idData),
      _ => throw ArgumentError('Unsupported ID type'),
    };

    final lastModified = DateTime.tryParse(map['lastModified']);
    if (lastModified == null) {
      throw Exception('NotificationModel lastModified is null');
    }

    final isPushOn = map['isPushOn'] as bool;

    return NotificationModel(
      isPushOn: isPushOn,
      scheduledTaskId: scheduledTaskId,
      lastModified: lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPushOn': isPushOn,
      'scheduledTaskId': scheduledTaskId.id.hexString,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  Map<String, dynamic> toMongoMap() {
    return {
      'isPushOn': isPushOn,
      'scheduledTaskId': scheduledTaskId,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  String get scheduledTaskIdString => scheduledTaskId.id.hexString;

  @override
  String toString() {
    return 'NotificationModel{scheduledTaskId: $scheduledTaskId, lastModified: $lastModified, isPushOn: $isPushOn}';
  }
}
