import 'package:mongo_dart/mongo_dart.dart';
import 'package:myserver/models/event.dart';

class User {
  final ObjectId id;
  final DateTime createdAt;
  final String deviceToken;
  final List<IEventModel> events;

  User({
    required this.id,
    required this.deviceToken,
    required this.events,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    try {
      final id = map['_id'] as ObjectId;
      final deviceToken = map['deviceToken'] as String;
      final events = List<IEventModel>.from(
        map['events']?.map(
          (e) => IEventModel.fromMap(e),
        ),
      );

      final createdAtRaw = map['createdAt'];
      if (createdAtRaw == null) {
        throw Exception('User createdAt is null');
      }

      final createdAt = DateTime.tryParse(map['createdAt']);

      if (createdAt == null) {
        throw Exception('User createdAt is null');
      }

      return User(
        id: id,
        deviceToken: deviceToken,
        events: events,
        createdAt: createdAt,
      );
    } catch (e) {
      throw Exception('Error parsing User from map: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'deviceToken': deviceToken,
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
