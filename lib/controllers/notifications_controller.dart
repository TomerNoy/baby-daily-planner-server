import 'package:myserver/controllers/global_functions.dart';
import 'package:myserver/controllers/responses.dart';
import 'package:myserver/services/services.dart';
import 'package:shelf/shelf.dart';

class NotificationsController {
  /// creates a notification task
  static Future<String?> createNotificationTask({
    required String userId,
    required String eventId,
    required String time,
  }) async {
    final schedule = _parseEventTime(time);

    final task = await notificationService.createCloudTask(
      userId: userId,
      eventId: eventId,
      schedule: schedule,
    );

    if (task == null) {
      loggerService.error('Failed to schedule notification');
      return null;
    }
    return task;
  }

  /// delete a notification task
  // static Future<bool> deleteNotificationTask({
  //   required String userId,
  //   required String eventId,
  // }) async {
  //   final task = await notificationService.deleteCloudTask(userId, eventId);
  //
  //   if (task == null) {
  //     loggerService.error('Failed to schedule notification');
  //     return false;
  //   }
  //   return true;
  // }

  /// toggle push notification for an event
  static Future<Response> toggleNotification(
      Request req, String eventId) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final isPushOn = body['isPushOn'] as bool?;

    loggerService.debug('isPushOn: $isPushOn for eventId: $eventId');
    if (isPushOn == null) {
      return Responses.badRequest('isPushOn cannot be null');
    }

    return Responses.ok();
  }

  /// toggle push notification for all events
  static Future<Response> pauseResumeNotifications(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('user not found');
    }

    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      return Responses.badRequest('body cannot be empty');
    }

    final isPushOn = body['isPushOn'] as bool?;

    loggerService.debug('isPushOn: $isPushOn');
    if (isPushOn == null) {
      return Responses.badRequest('isPushOn cannot be null');
    }

    return Responses.ok();
  }

  /// sends a push notification to a client
  static Future<Response> sendNotificationToClient(Request req) async {
    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      loggerService.error('Invalid request body', StackTrace.current);
      return Responses.ok();
    }

    loggerService.debug('body: $body');

    final userId = body['userId'];
    final eventId = body['eventId'];

    if (userId == null || eventId == null) {
      loggerService.error('Missing required fields', StackTrace.current);
      return Responses.ok();
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      loggerService.warning('User not found');
      return Responses.ok();
    }

    final deviceToken = user['deviceToken'];
    if (deviceToken == null) {
      loggerService.error('deviceToken was null', StackTrace.current);
      return Responses.ok();
    }
    final decryptedToken = decryptionService.decryptToken(deviceToken);

    final event = mongoService.getEventFromUser(user, eventId);
    if (event == null) {
      loggerService.error('event not found', StackTrace.current);
      return Responses.ok();
    }

    final title = _getEventTitle(event);

    final message = event['message'] as String? ?? '';

    // send push to client
    try {
      await notificationService.sendPushToClient(
        token: decryptedToken,
        title: title,
        message: message,
      );
    } catch (e) {
      loggerService.error('Failed to send push notification', e);
      return Responses.ok();
    }

    // schedule next notification
    final time = event['time'] as String?;

    if (time == null) {
      loggerService.error('event time is null');
      return Responses.ok();
    }

    try {
      final schedule = _parseEventTime(time).add(Duration(days: 1));
      await notificationService.createCloudTask(
        userId: userId,
        eventId: eventId,
        schedule: schedule,
      );
    } catch (e) {
      loggerService.error(
        'Failed to schedule notification',
        e,
        StackTrace.current,
      );
      return Responses.ok();
    }
    return Responses.ok();
  }

  /// global functions
  static DateTime _parseEventTime(String time) {
    final parts = time.split(':');
    return DateTime.now().copyWith(
      hour: int.tryParse(parts[0]),
      minute: int.tryParse(parts[1]),
      second: 0,
    );
  }

  static String _getEventTitle(Map<String, dynamic> event) {
    return switch (event['eventType']) {
      'feed' => 'Baby Feed',
      'sleep' => 'Baby Sleep ${event['sleepType']?.toUpperCase() ?? 'UNKNOWN'}',
      _ => 'Baby Event',
    };
  }
}
