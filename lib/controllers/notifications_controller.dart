import 'package:myserver/controllers/global_functions.dart';
import 'package:myserver/controllers/responses.dart';
import 'package:myserver/models/event.dart';
import 'package:myserver/services/services.dart';
import 'package:shelf/shelf.dart';

class NotificationsController {
  /// creates a notification task
  static Future<String?> createNotificationTask({
    required String userId,
    required IEventModel eventModel,
  }) async {
    final now = DateTime.now();

    var schedule = now.copyWith(
      hour: eventModel.time.hour,
      minute: eventModel.time.minute,
      second: 0,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(Duration(days: 1));
      loggerService.debug('time was changed to tomorrow $schedule');
    }

    final taskName = await notificationService.createCloudTask(
      userId: userId,
      eventModel: eventModel,
      schedule: schedule,
    );

    if (taskName == null) {
      loggerService.error('Failed to schedule notification');
      return null;
    }
    return taskName;
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
  static Future<Response> queueResponse(Request req) async {
    final body = await GlobalFunctions.extractBody(req);
    if (body == null) {
      loggerService.error('Invalid request body', StackTrace.current);
      return Responses.ok();
    }

    loggerService.debug('body: $body');

    final userId = body['userId'];
    final eventId = body['eventId'];
    final taskId = body['taskId'];

    if (userId == null || eventId == null) {
      loggerService.error('Missing required fields', StackTrace.current);
      return Responses.ok();
    }

    final user = await mongoService.getUserById(userId);
    if (user == null) {
      loggerService.warning('User not found');
      return Responses.ok();
    }

    final eventModel = user.eventById(eventId);

    if (eventModel == null) {
      loggerService.error('event not found', StackTrace.current);
      return Responses.ok();
    }

    // check if push is on
    final isPushOn = eventModel.notificationModel.isPushOn;
    if (!isPushOn) {
      loggerService.debug('Push notification was off');
      return Responses.ok();
    }

    // check time is within 1 minute
    final now = DateTime.now();
    final duration = Duration(seconds: 65);
    if (eventModel.time.difference(now).abs() > duration) {
      loggerService.debug('Time diff was not within 65s');
      return Responses.ok();
    }

    // check if id matches
    if (eventModel.notificationModel.scheduledTaskIdString != taskId) {
      loggerService.error('taskId did not match', StackTrace.current);
      return Responses.ok();
    }

    final deviceToken = user.deviceToken;
    if (deviceToken.isEmpty) {
      loggerService.error('deviceToken was null', StackTrace.current);
      return Responses.ok();
    }
    final decryptedToken = decryptionService.decryptToken(deviceToken);

    final title = _getEventTitle(eventModel);

    final message = eventModel.message;

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
    final time = DateTime.now().copyWith(
      hour: eventModel.time.hour,
      minute: eventModel.time.minute,
      second: 0,
    );

    final newTaskId = mongoService.newTaskId;

    try {
      final schedule = time.add(Duration(days: 1));
      final taskName = await notificationService.createCloudTask(
        userId: userId,
        eventModel: eventModel,
        schedule: schedule,
      );

      if (taskName == null) {
        loggerService.error('Failed to schedule notification');
      } else {
        loggerService.debug('Task scheduled: $taskName');
      }
    } catch (e) {
      loggerService.error(
        'Failed to schedule notification',
        e,
        StackTrace.current,
      );
      return Responses.ok();
    }

    // update notification id
    final update = await mongoService.updateNotificationId(
      userId,
      eventId,
      newTaskId,
    );

    if (!update) {
      loggerService.error('Failed to update notification id');
      return Responses.ok();
    }

    return Responses.ok();
  }

  static String _getEventTitle(IEventModel event) {
    return switch (event.eventType) {
      EventType.feed => 'Baby Feed',
      EventType.sleep => 'Baby Sleep ${event.eventType.name.toUpperCase()}',
      _ => 'Baby Event',
    };
  }
}
