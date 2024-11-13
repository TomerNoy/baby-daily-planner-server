class Constants {
  /// server
  static const String rootPath = '/';
  static const String echoPath = '/echo/<message>';
  static const String defaultPort = '8080';

  /// http
  static const headers = {'Content-Type': 'application/json'};

  /// mongo
  static const int maxMongoRetries = 6;
  static const mongoConnectDelay = Duration(seconds: 3);

  /// paths
  static const register = '/auth/register';
  static const reRegister = '/auth/re-register';
  static const refresh = '/auth/refresh';
  static const events = '/events';
  static const addEvent = '/events/add-one';
  static const update = '/events/update';
  static const addMany = '/events/add-many';
  static const deleteOne = '/events/delete-one';
  static const deleteMany = '/events/delete-many';
  static const deleteAll = '/events/delete-all';
  static const notificationAddOne = '/notifications/add-one';
  static const toggleNotification = '/notifications/<eventId>';
  static const pauseResumeNotifications = '/notifications/pause-resume';
  static const queueResponse = '/notifications/queue-response';

  /// notification
  static const serviceAccountCredentialsPath = 'baby-daily-planner-key.json';
  static const authClientScopes = [
    'https://www.googleapis.com/auth/cloud-platform'
  ];
  static const location = 'projects/baby-daily-planner/locations/us-central1';
  static const queueName = '$location/queues/notification-task-queue';
  static const serverCallbackUrl =
      'https://5894-2a00-a041-3a25-a00-a51c-ceca-6dd3-f7e1.ngrok-free.app/notifications/queue-response';
  static const taskHttpMethod = 'POST';
  static const sendPushUrl =
      'https://fcm.googleapis.com/v1/projects/baby-daily-planner/messages:send';
}
