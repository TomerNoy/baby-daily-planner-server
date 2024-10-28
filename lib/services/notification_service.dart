import 'dart:convert';
import 'dart:io';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:myserver/config/constants.dart';
import 'package:myserver/services/services.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  AuthClient? _authClient;

  Future<void> init() async {
    _authClient = await _getAuthClient();
  }

  Future<String?> createCloudTask({
    required String userId,
    required String eventId,
    required DateTime schedule,
  }) async {
    if (_authClient == null) {
      loggerService.error('AuthClient not initialized');
      return null;
    }

    var cloudTasks = CloudTasksApi(_authClient!);
    var scheduledTime = schedule.toUtc().toIso8601String();
    final taskContent = {'userId': userId, 'eventId': eventId};
    final taskIdentifier = createTaskIdentifier(userId, eventId);

    var task = Task()
      ..name = '${Constants.queueName}/tasks/$taskIdentifier'
      ..scheduleTime = scheduledTime
      ..dispatchDeadline = '60s'
      ..httpRequest = HttpRequest(
        url: Constants.serverCallbackUrl,
        httpMethod: Constants.taskHttpMethod,
        headers: Constants.headers,
        body: base64Encode(utf8.encode(jsonEncode(taskContent))),
      );

    var request = CreateTaskRequest()..task = task;

    final createdTask = await cloudTasks.projects.locations.queues.tasks.create(
      request,
      Constants.queueName,
    );

    loggerService.debug('Task created: ${createdTask.name}');
    return taskIdentifier;
  }

  Future<void> deleteCloudTask(String taskName) async {
    if (_authClient == null) {
      loggerService.error('AuthClient not initialized');
      return;
    }

    var cloudTasks = CloudTasksApi(_authClient!);

    try {
      // The full task path includes the project, location, queue, and task name
      final taskPath = '${Constants.queueName}/tasks/$taskName';
      await cloudTasks.projects.locations.queues.tasks.delete(taskPath);
      loggerService.debug('Task $taskName deleted successfully');
    } catch (e) {
      loggerService.error('Failed to delete task: $e', StackTrace.current);
    }
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

    // create a new task for next cycle
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

  String createTaskIdentifier(String userId, String eventId) {
    final uuid = Uuid().v4();
    return 'userId-${userId}_eventId-${eventId}_uuid-$uuid';
  }

  Map<String, String> parseTaskIdentifier(String taskIdentifier) {
    final parts = taskIdentifier.split('_');
    final userId = parts[0].split('-')[1];
    final eventId = parts[1].split('-')[1];
    final uuid = parts[2].split('-')[1];
    return {'userId': userId, 'eventId': eventId, 'uuid': uuid};
  }
}