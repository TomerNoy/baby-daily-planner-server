import 'package:myserver/models/event.dart';

class User {
  User({
    required this.userId,
    this.deviceToken,
    this.events = const [],
  });

  final String userId;
  String? deviceToken;
  List<IBabyEvent> events;
}
