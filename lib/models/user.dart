import 'package:mongo_dart/mongo_dart.dart';
import 'package:myserver/models/event.dart';

class UserModel {
  UserModel({
    ObjectId? id,
    DateTime? createdAt,
    String? deviceToken,
    List<IEventModel>? events,
  })  : createdAt = createdAt ?? DateTime.now(),
        id = id ?? ObjectId(),
        deviceToken = deviceToken ?? '',
        events = events ?? [];

  final ObjectId id;
  final DateTime createdAt;
  final String deviceToken;
  final List<IEventModel> events;

  String get idString => id.id.hexString;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      final id = switch (map['_id']) {
        ObjectId _id => _id,
        String _id => ObjectId.fromHexString(_id),
        _ => throw ArgumentError('Unsupported ID type'),
      };

      // fromMongo ? idRaw as ObjectId : ObjectId.fromHexString(idRaw);

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

      return UserModel(
        id: id,
        deviceToken: deviceToken,
        events: events,
        createdAt: createdAt,
      );
    } catch (e, st) {
      throw Exception('Error parsing User from map: $e, $st');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id.id.hexString,
      'deviceToken': deviceToken,
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMongoMap() {
    return {
      '_id': id,
      'deviceToken': deviceToken,
      'events': events.map((e) => e.toMongoMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool eventExists(String eventId) {
    return events.any((element) => element.id.id.hexString == eventId);
  }

  IEventModel? eventById(String eventId) {
    return events.cast<IEventModel?>().firstWhere(
          (element) => element?.id.id.hexString == eventId,
          orElse: () => null,
        );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, createdAt: $createdAt, deviceToken: $deviceToken, events: $events}';
  }
}
