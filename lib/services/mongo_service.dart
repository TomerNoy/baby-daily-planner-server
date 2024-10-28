import 'dart:io';

import 'package:myserver/services/dotenv_service.dart';
import 'package:myserver/services/notification_service.dart';
import 'package:myserver/services/services.dart';

import '../config/constants.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  MongoService(this._dotEnvService, this._notificationService);

  final DotEnvService _dotEnvService;
  final NotificationService _notificationService;

  Db? _db;

  DbCollection? get _usersCollection => _db?.collection('users');

  Future<void> connect({int maxAttempts = Constants.maxMongoRetries}) async {
    var failedAttempts = 0;
    final mongoUri = _dotEnvService.getEnv('MONGODB_URI');
    _db = Db(mongoUri);

    while (failedAttempts < maxAttempts) {
      try {
        await _db?.open();
        loggerService.info('Connected to the MongoDB database');
        return;
      } catch (e) {
        failedAttempts++;
        loggerService.error(
            'Error connecting to MongoDB: Attempt $failedAttempts of $maxAttempts)',
            e,
            StackTrace.current);
        await Future.delayed(Constants.mongoConnectDelay);
      }
    }
    await close();
    exit(1);
  }

  Future<void> close() async {
    try {
      await _db?.close();
      loggerService.warning('MongoDB connection closed');
    } catch (e) {
      loggerService.error(
        'Error closing MongoDB connection',
        e,
        StackTrace.current,
      );
    }
  }

  Future<String?> addNewUser() async {
    final newUser = {'createdAt': DateTime.now(), 'events': []};
    try {
      final user = await _usersCollection?.insertOne(newUser);
      if (user == null || !user.isSuccess) {
        return null;
      }

      final userId = (user.id as ObjectId).id.hexString;
      return userId;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final user = await _usersCollection?.findOne(_userQuery(userId));
      return user;
    } catch (e) {
      loggerService.error('findUserFromDB error $e');
      return null;
    }
  }

  String generateId() => ObjectId().id.hexString;

  Future<Map<String, dynamic>?> addEventToUser(
    String userId,
    Map<String, dynamic> event,
  ) async {
    try {
      event['id'] = ObjectId.fromHexString(event['id']);
      final updateResult = await _usersCollection?.updateOne(
        _userQuery(userId),
        modify.push('events', event),
      );

      if (updateResult?.isAcknowledged ?? false) {
        return event;
      }
      loggerService.error('addEventToUser failed to add event');
      return null;
    } catch (e) {
      loggerService.error('addEventToUser error $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateEvent(
    String userId,
    String eventId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final updateResult = await _usersCollection?.findAndModify(
        returnNew: true,
        query: {
          '_id': _getObjectId(userId),
          'events.id': _getObjectId(eventId),
        },
        update: {
          '\$set': updateData.map(
            (key, value) => MapEntry('events.\$.$key', value),
          ),
        },
      );
      if (updateResult?.isEmpty ?? true) {
        loggerService.error('updateResult $updateResult');
        return null;
      }
      return updateResult!['events'].firstWhere(
        (e) => e['id'] == _getObjectId(eventId),
      );
    } catch (e) {
      loggerService.error('updateEvent error $e');
      return null;
    }
  }

  Future<bool> deleteEventFromUser(String eventId, String userId) async {
    final objId = _getObjectId(eventId);
    return await _deleteEventsFromUser(userId, eventIds: [objId]);
  }

  Future<bool> deleteEventsFromUser(
    List<String> eventIds,
    String userId,
  ) async {
    final eventObjIds = eventIds.map((id) => _getObjectId(id)).toList();
    return await _deleteEventsFromUser(userId, eventIds: eventObjIds);
  }

  Future<bool> deleteAllEventsFromUser(String userId) async {
    return await _deleteEventsFromUser(userId);
  }

  Future<bool> updateDeviceToken(String userId, String deviceToken) async {
    final update = modify.set('deviceToken', deviceToken);
    final result = await _usersCollection?.updateOne(
      _userQuery(userId),
      update,
    );

    if (result == null || !result.isAcknowledged) {
      loggerService.error('updating device token failed: ${result?.errmsg}');
      return false;
    }
    return true;
  }

  bool checkIsEventExists(List<dynamic> events, String eventId) {
    return events.any((e) => e['id'] == _getObjectId(eventId));
  }

  Future<Map<String, dynamic>?> getEventFromUserId(
    String userId,
    String eventId,
  ) async {
    try {
      final event = await _usersCollection?.findOne(
        _userQuery(userId).fields(['events']).eq(
          'events.id',
          _getObjectId(eventId),
        ),
      );
      if (event?.isEmpty ?? true) {
        loggerService.error('getEventFromUser failed to get event');
        return null;
      }
      return event;
    } catch (e) {
      return null;
    }
  }

  /// global functions
  SelectorBuilder _userQuery(String userId) {
    return where.eq('_id', _getObjectId(userId));
  }

  bool _isUpdateAcknowledged(WriteResult? result) {
    if (result == null || !result.isAcknowledged || result.nModified == 0) {
      loggerService.error('Update operation failed', StackTrace.current);
      return false;
    }
    return true;
  }

  Map<String, dynamic>? getEventFromUser(
    Map<String, dynamic> user,
    String eventId,
  ) {
    final events = user['events'] as List<dynamic>? ?? [];
    return events.firstWhere(
      (e) => e['id'] == _getObjectId(eventId),
      orElse: () => null,
    );
  }

  Future<bool> _deleteEventsFromUser(String userId,
      {List<ObjectId>? eventIds}) async {
    try {
      final query = _userQuery(userId);
      final update = (eventIds == null)
          ? modify.set('events', [])
          : modify.pull('events', {
              'id': {'\$in': eventIds}
            });

      final updateResult = await _usersCollection?.updateOne(query, update);
      return _isUpdateAcknowledged(updateResult);
    } catch (e) {
      loggerService.error('deleteEventsFromUser error $e');
      return false;
    }
  }

  ObjectId _getObjectId(String hexString) {
    return ObjectId.fromHexString(hexString);
  }
}
