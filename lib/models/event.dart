enum EventType { sleep, feed, other }

enum SleepType { start, end }

// todo: other event is the same as parent maybe just return the parent
abstract class IBabyEvent {
  IBabyEvent({
    required this.eventType,
    required this.id,
    required this.time,
    required this.isPushOn,
    this.message = '',
  });

  final String id;
  final DateTime time;
  final String message;
  final EventType eventType;
  bool isPushOn;

  static IBabyEvent mapToEvent(Map<String, dynamic> map) {
    final timeRaw = map['time'];

    if (timeRaw == null) {
      throw Exception('event time is null');
    }

    List<String> parts = timeRaw.split(":");

    var time = DateTime.now().copyWith(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
      second: 0,
    );

    switch (map['eventType']) {
      case 'feed':
        return FeedEvent(
          time: time,
          amount: map['amount'] as int,
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.feed,
          isPushOn: map['isPushOn'],
        );
      case 'sleep':
        return SleepEvent(
          time: time,
          sleepType: SleepType.values.firstWhere(
            (e) => e.name == map['sleepType'],
          ),
          linkedID: map['linkedID'],
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.sleep,
          isPushOn: map['isPushOn'],
        );
      case 'other':
        return OtherEvent(
          time: time,
          message: map['message'] ?? '',
          id: map['id'],
          eventType: EventType.other,
          isPushOn: map['isPushOn'],
        );
      default:
        throw Exception('Event type "${map['type']}" not recognized');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': '${time.hour}:${time.minute}',
      'message': message,
      'eventType': eventType.name,
      'isPushOn': isPushOn,
    };
  }

  @override
  String toString() {
    return 'IBabyEvent{id: $id, time: $time, message: $message, eventType: $eventType, isPushOn: $isPushOn}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IBabyEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}

class SleepEvent extends IBabyEvent {
  SleepEvent({
    required super.eventType,
    required super.id,
    required super.time,
    required this.sleepType,
    required this.linkedID,
    required super.isPushOn,
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

class FeedEvent extends IBabyEvent {
  FeedEvent({
    required super.eventType,
    required super.id,
    required super.time,
    required this.amount,
    super.message = '',
    super.isPushOn = true,
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

class OtherEvent extends IBabyEvent {
  OtherEvent({
    required super.eventType,
    required super.id,
    required super.time,
    super.message = '',
    super.isPushOn = true,
  });
}
