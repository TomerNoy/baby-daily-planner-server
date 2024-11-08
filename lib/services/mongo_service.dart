import 'dart:io';

import 'package:myserver/models/event.dart';
import 'package:myserver/models/user.dart';
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

  Future<UserModel?> addNewUser() async {
    final newUser = UserModel();

    try {
      final user = await _usersCollection?.insertOne(newUser.toMongoMap());
      if (user == null || !user.isSuccess) {
        loggerService.error('addNewUser failed to add user');
        return null;
      }
      return newUser;
    } catch (e) {
      loggerService.error('addNewUser error $e');
      return null;
    }
  }

  Future<bool> checkIfUserExists(String userId) async {
    try {
      final count = await _usersCollection?.count(
        _userQuery(userId),
      );
      return (count ?? 0) > 0;
    } catch (e) {
      loggerService.error('checkIfUserExists error $e');
      return false;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final user = await _usersCollection?.findOne(_userQuery(userId));
      if (user?.isEmpty ?? true) {
        loggerService.error('getUserById failed to get user');
        return null;
      }

      loggerService.debug('getUserById user: $user');

      final userModel = UserModel.fromMap(user!);
      return userModel;
    } catch (e, st) {
      loggerService.error('getUserById error $e', st);
      return null;
    }
  }

  Future<bool> addEventToUser(String userId, IEventModel eventModel) async {
    try {
      final updateResult = await _usersCollection?.updateOne(
        _userQuery(userId),
        modify.push('events', eventModel.toMongoMap()),
      );

      loggerService.debug('updateResult: ${updateResult?.isAcknowledged}');

      if (updateResult?.isAcknowledged ?? false) {
        return true;
      }
      loggerService.error(
        'addEventToUser failed to add event',
        StackTrace.current,
      );
      return false;
    } catch (e, st) {
      loggerService.error('addEventToUser error $e', st);
      return false;
    }
  }

  Future<IEventModel?> updateEvent(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    final eventId = updateData['id'] as String?;
    if (eventId?.isEmpty == true) {
      loggerService.error('updateEvent eventId is empty');
      return null;
    }
    updateData.remove('id');
    try {
      loggerService.debug('updateEvent $updateData');
      final updateResult = await _usersCollection?.findAndModify(
        returnNew: true,
        query: {
          '_id': _getObjectId(userId),
          'events.id': _getObjectId(eventId!),
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
      final updatedEvent = updateResult!['events'].firstWhere(
        (e) => e['id'] == _getObjectId(eventId!),
      );

      print('updatedEvent: $updatedEvent');

      final eventModel = IEventModel.fromMap(updatedEvent);

      return eventModel;
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

  Future<IEventModel?> getEventFromUserId(
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
      final eventModel = IEventModel.fromMap(event!);
      return eventModel;
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
