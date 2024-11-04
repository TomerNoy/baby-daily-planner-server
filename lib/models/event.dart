import 'package:myserver/models/notification.dart';

enum EventType { sleep, feed, other }

enum SleepType { start, end }

abstract class IEventModel {
  IEventModel({
    required this.eventType,
    required this.id,
    required this.time,
    required this.notificationModel,
    this.message = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final DateTime time;
  final DateTime createdAt;
  final String message;
  final EventType eventType;
  final NotificationModel notificationModel;

  factory IEventModel.fromMap(Map<String, dynamic> map) {
    final timeRaw = map['time'];
    final createdAtRaw = map['createdAt'];

    if (timeRaw == null || createdAtRaw == null) {
      throw Exception('event time is null');
    }

    final time = DateTime.tryParse(timeRaw);
    final createdAt = DateTime.tryParse(createdAtRaw);

    if (time == null || createdAt == null) {
      throw Exception('event time format is invalid');
    }

    final eventType = EventType.values.firstWhere(
      (e) => e.name == map['eventType'],
    );

    switch (eventType) {
      case EventType.feed:
        return FeedEventModel(
          time: time,
          createdAt: createdAt,
          amount: map['amount'] as int,
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.feed,
          notificationModel: NotificationModel.fromMap(
            map['notificationModel'],
          ),
        );
      case EventType.sleep:
        return SleepEventModel(
          time: time,
          createdAt: createdAt,
          sleepType: SleepType.values.firstWhere(
            (e) => e.name == map['sleepType'],
          ),
          linkedID: map['linkedID'],
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.sleep,
          notificationModel: NotificationModel.fromMap(
            map['notificationModel'],
          ),
        );
      case EventType.other:
        return OtherEventModel(
          time: time,
          createdAt: createdAt,
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.other,
          notificationModel: NotificationModel.fromMap(
            map['notificationModel'],
          ),
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': '${time.hour}:${time.minute}',
      'message': message,
      'eventType': eventType.name,
      'notificationModel': notificationModel.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'IEventModel{id: $id, time: $time, createdAt: $createdAt, message: $message, eventType: $eventType, notificationModel: $notificationModel}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IEventModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

class SleepEventModel extends IEventModel {
  SleepEventModel({
    required super.eventType,
    required super.id,
    required super.time,
    required super.createdAt,
    required this.sleepType,
    required this.linkedID,
    required super.notificationModel,
    super.message,
  });

  final SleepType sleepType;
  final String linkedID;

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'sleepType': sleepType.name,
      'linkedID': linkedID,
    });
    return map;
  }

  @override
  String toString() {
    return '${super.toString()}, sleepType: $sleepType, linkedID: $linkedID}';
  }
}

class FeedEventModel extends IEventModel {
  FeedEventModel({
    required super.eventType,
    required super.id,
    required super.time,
    required super.createdAt,
    required this.amount,
    required super.notificationModel,
    super.message = '',
  });

  final int amount;

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'amount': amount,
    });
    return map;
  }

  @override
  String toString() => '${super.toString()}, amount: $amount}';
}

class OtherEventModel extends IEventModel {
  OtherEventModel({
    required super.eventType,
    required super.id,
    required super.time,
    required super.notificationModel,
    required super.createdAt,
    super.message = '',
  });
}
