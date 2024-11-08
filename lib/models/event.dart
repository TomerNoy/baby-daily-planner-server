import 'package:mongo_dart/mongo_dart.dart';
import 'package:myserver/models/notification.dart';
import 'package:myserver/services/services.dart';

enum EventType { sleep, feed, other }

enum SleepType { start, end }

abstract class IEventModel {
  IEventModel({
    ObjectId? id,
    DateTime? createdAt,
    required this.eventType,
    required this.notificationModel,
    required this.time,
    this.message = '',
  })  : createdAt = createdAt ?? DateTime.now(),
        id = id ?? ObjectId();

  final ObjectId id;
  final DateTime time;
  final DateTime createdAt;
  final String message;
  final EventType eventType;
  final NotificationModel notificationModel;

  static IEventModel? createEvent(Map<String, dynamic> event) {
    try {
      final eventType = EventType.values.firstWhere(
        (e) => e.name == event['eventType'],
      );

      final time = DateTime.tryParse(event['time']);
      if (time == null) {
        throw Exception('event time format is invalid');
      }

      final createdAt = DateTime.now();

      final id = ObjectId();

      final message = event['message'] ?? '';

      final notificationModel = NotificationModel(
        isPushOn: event['notificationModel']['isPushOn'] as bool,
      );

      return switch (eventType) {
        EventType.sleep => SleepEventModel(
            time: time,
            createdAt: createdAt,
            sleepType: SleepType.values.firstWhere(
              (e) => e.name == event['sleepType'],
            ),
            linkedID: event['linkedID'] as String,
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
          ),
        EventType.feed => FeedEventModel(
            time: time,
            createdAt: createdAt,
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
            amount: event['amount'] as int),
        EventType.other => OtherEventModel(
            time: time,
            createdAt: createdAt,
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
          )
      };
    } catch (e, st) {
      loggerService.error('Error creating IEventModel: $e', st);
      return null;
    }
  }

  factory IEventModel.fromMap(Map<String, dynamic> map) {
    loggerService.debug('IEventModel.fromMap: $map');

    try {
      final timeRaw = map['time'];
      final createdAtRaw = map['createdAt'];

      if (timeRaw == null || createdAtRaw == null) {
        throw Exception('event time is null');
      }

      final time = DateTime.tryParse(timeRaw);
      final createdAt = DateTime.tryParse(createdAtRaw);

      loggerService.debug('time: $time, createdAt: $createdAt');

      if (time == null || createdAt == null) {
        throw Exception('event time format is invalid');
      }

      final eventType = EventType.values.firstWhere(
        (e) => e.name == map['eventType'],
      );

      final id = switch (map['id']) {
        ObjectId _id => _id,
        String _id => ObjectId.fromHexString(_id),
        _ => throw ArgumentError('Unsupported ID type'),
      };

      final message = map['message'] ?? '';

      final notificationModel = NotificationModel.fromMap(
        map['notificationModel'],
      );

      return switch (eventType) {
        EventType.feed => FeedEventModel(
            time: time,
            createdAt: createdAt,
            amount: map['amount'] as int,
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
          ),
        EventType.sleep => SleepEventModel(
            time: time,
            createdAt: createdAt,
            sleepType: SleepType.values.firstWhere(
              (e) => e.name == map['sleepType'],
            ),
            linkedID: map['linkedID'],
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
          ),
        EventType.other => OtherEventModel(
            time: time,
            createdAt: createdAt,
            message: message,
            id: id,
            eventType: eventType,
            notificationModel: notificationModel,
          )
      };
    } catch (e, st) {
      loggerService.error('Error parsing IEventModel from map: $e', st);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.id.hexString,
      'time': time.toIso8601String(),
      'message': message,
      'eventType': eventType.name,
      'notificationModel': notificationModel.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMongoMap() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'message': message,
      'eventType': eventType.name,
      'notificationModel': notificationModel.toMongoMap(),
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
    super.id,
    super.createdAt,
    required super.eventType,
    required super.time,
    required super.notificationModel,
    required this.sleepType,
    required this.linkedID,
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
  Map<String, dynamic> toMongoMap() {
    final map = super.toMongoMap();
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
  Map<String, dynamic> toMongoMap() {
    final map = super.toMongoMap();
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
