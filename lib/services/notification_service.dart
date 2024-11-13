import 'dart:convert';
import 'dart:io';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:myserver/config/constants.dart';
import 'package:myserver/models/event.dart';
import 'package:myserver/services/services.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  AuthClient? _authClient;

  Future<void> init() async {
    _authClient = await _getAuthClient();
  }

  // todo: refactor to use event model
  Future<String?> createCloudTask({
    required String userId,
    required IEventModel eventModel,
    required DateTime schedule,
  }) async {
    if (_authClient == null) {
      loggerService.error('AuthClient not initialized');
      return null;
    }

    final cloudTasks = CloudTasksApi(_authClient!);
    final scheduledTime = schedule.toUtc().toIso8601String();
    final taskId = eventModel.notificationModel.scheduledTaskIdString;
    final eventId = eventModel.idString;

    final taskContent = {
      'userId': userId,
      'eventId': eventId,
      'taskId': taskId,
    };

    final taskName = createTaskName(userId, eventId, taskId);
    final body = base64Encode(utf8.encode(jsonEncode(taskContent)));
    final name = '${Constants.queueName}/tasks/$taskName';
    final httpRequest = HttpRequest(
      url: Constants.serverCallbackUrl,
      httpMethod: Constants.taskHttpMethod,
      headers: Constants.headers,
      body: body,
    );

    var task = Task()
      ..name = name
      ..scheduleTime = scheduledTime
      ..dispatchDeadline = '60s'
      ..httpRequest = httpRequest;

    var request = CreateTaskRequest()..task = task;

    final createdTask = await cloudTasks.projects.locations.queues.tasks.create(
      request,
      Constants.queueName,
    );

    loggerService.debug(
      'Task created: ${createdTask.name}, dispatched at ${createdTask.dispatchDeadline}, schedule at ${createdTask.scheduleTime}',
    );
    return taskName;
  }

  // Modify sendPushNotification to use HTTP v1 API and OAuth2 access token
  Future<void> sendPushToClient({
    required String token,
    required String title,
    required String message,
  }) async {
    // Get OAuth2 access token from service account credentials
    if (_authClient == null) {
      loggerService.error('AuthClient not initialized');
      return;
    }

    // Define the v1 API payload
    final payload = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': message},
      },
    };

    // Make the HTTP request to FCM v1 API using the access token
    final response = await _authClient?.post(
      Uri.parse(Constants.sendPushUrl),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response?.statusCode == 200) {
      loggerService.debug('Notification sent.');
    } else {
      loggerService.error(
        'Failed to send notification: ${response?.statusCode} - ${response?.body}',
        StackTrace.current,
      );
    }
  }

  Future<AuthClient> _getAuthClient() async {
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      await File(Constants.serviceAccountCredentialsPath).readAsString(),
    );

    return clientViaServiceAccount(
      serviceAccountCredentials,
      Constants.authClientScopes,
    );
  }

  String createTaskName(
    String userId,
    String eventId,
    String taskId,
  ) {
    return 'userId-${userId}_eventId-${eventId}_taskId-$taskId';
  }

  Map<String, String> parseTaskName(String taskIdentifier) {
    final parts = taskIdentifier.split('_');
    final userId = parts[0].split('-')[1];
    final eventId = parts[1].split('-')[1];
    final taskId = parts[2].split('-')[1];
    return {'userId': userId, 'eventId': eventId, 'taskId': taskId};
  }
}
