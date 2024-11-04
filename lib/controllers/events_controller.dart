import 'package:myserver/controllers/global_functions.dart';
import 'package:myserver/controllers/responses.dart';
import 'package:myserver/services/services.dart';
import 'package:shelf/shelf.dart';

class EventsController {
  /// gets all user events
  static Future<Response> events(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final deviceToken = body['deviceToken'] as String;
    if (deviceToken.isEmpty) {
      loggerService.error('deviceToken was empty');
    } else {
      final deviceTokenUpdated =
          await mongoService.updateDeviceToken(userId, deviceToken);
      if (!deviceTokenUpdated) {
        loggerService.error('Failed to update device token');
      }
    }

    final events = user['events'] as List<dynamic>? ?? [];

    return Responses.ok({'events': events});
  }

  /// adds event to a user and returns the event id
  static Future<Response> addEvent(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final event = body['event'];
    if (event == null || event.isEmpty) {
      return Responses.badRequest('event cannot be empty');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('user not found');
    }

    final eventStringId = mongoService.generateId();
    event['id'] = eventStringId;

    // final isPushOn = event['isPushOn'] as bool?;
    //
    // if (isPushOn == null) {
    //   loggerService.error('isPushOn was null', StackTrace.current);
    // }

    // if (isPushOn!) {
    //   final taskUuid = await NotificationsController.createNotificationTask(
    //     userId: userId,
    //     eventId: eventStringId,
    //     time: event['time'] as String,
    //   );
    //
    //   loggerService.debug('addNotification task: $taskUuid');
    // }

    final newEvent = await mongoService.addEventToUser(userId, event);
    if (newEvent == null) {
      return Responses.serverError('Failed to add event');
    }

    return Responses.ok({'event': newEvent});
  }

  /// updates event by key-value pair
  static Future<Response> update(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('User not found');
    }

    final updateData = body['update'] as Map<String, dynamic>?;
    if (updateData == null || updateData.isEmpty) {
      return Responses.badRequest('Update data cannot be empty');
    }

    final eventId = updateData['id'] as String?;
    if (eventId == null || eventId.isEmpty) {
      return Responses.badRequest('Invalid event ID or update data');
    }
    updateData.remove('id');

    final eventExists =
        mongoService.checkIsEventExists(user['events'], eventId);
    if (!eventExists) {
      return Responses.notFound('Event not found');
    }

    final event = await mongoService.updateEvent(userId, eventId, updateData);

    if (event == null) {
      return Responses.serverError('Failed to update event');
    }

    return Responses.ok({'event': event});
  }

  /// adds events to a user and returns the event id todo test
  static Future<Response> addMany(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final events = (body['events'] as List<dynamic>?);
    if (events == null) {
      return Responses.badRequest('event cannot be empty');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('user not found');
    }

    final eventsResponse = [];

    for (dynamic event in events) {
      final newEvent = await mongoService.addEventToUser(userId, event);
      if (newEvent == null) {
        return Responses.serverError('Failed to add event');
      }
      eventsResponse.add(newEvent);
    }

    return Responses.ok({'events': eventsResponse});
  }

  /// delete one event
  static Future<Response> deleteOne(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('user not found');
    }

    final eventId = body['eventId'] as String?;
    if (eventId == null || eventId.isEmpty) {
      return Responses.badRequest('eventId cannot be empty');
    }

    final eventDeleted =
        await mongoService.deleteEventFromUser(eventId, userId);

    // final eventNotificationDeleted =
    //     await NotificationsController.deleteNotificationTask(
    //   userId: userId,
    //   eventId: eventId,
    // );

    if (!eventDeleted) {
      loggerService.error('Failed to delete event', StackTrace.current);
      return Responses.serverError('Failed to delete event');
    }

    return Responses.ok({'success': 'event deleted'});
  }

  /// delete multiple events
  static Future<Response> deleteMany(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final List<dynamic>? eventIds = body['eventIds'];
    if (eventIds == null || eventIds.isEmpty) {
      return Responses.badRequest('eventIds cannot be empty');
    }

    List<String> stringList = eventIds.cast<String>();

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('user not found');
    }

    // Remove the specified events from the user's events array
    final eventsDeleted =
        await mongoService.deleteEventsFromUser(stringList, userId);
    if (!eventsDeleted) {
      return Responses.serverError('Failed to delete events');
    }

    return Responses.ok({'success': 'events deleted'});
  }

  /// delete all events
  static Future<Response> deleteAll(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      return Responses.notFound('user not found');
    }

    final eventsDeleted = await mongoService.deleteAllEventsFromUser(userId);
    if (!eventsDeleted) {
      return Responses.serverError('Failed to delete events');
    }

    return Responses.ok({'success': 'all events deleted'});
  }
}
