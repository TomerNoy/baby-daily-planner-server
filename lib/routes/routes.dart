import 'package:myserver/config/constants.dart';
import 'package:myserver/controllers/auth_controller.dart';
import 'package:myserver/controllers/events_controller.dart';
import 'package:myserver/controllers/notifications_controller.dart';
import 'package:myserver/middlewares/middlewares.dart';
import 'package:myserver/services/token_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router getRouter() {
  final router = Router();

  router.post(Constants.register, (req) {
    return Pipeline()
        .addMiddleware(secretKeyMiddleware())
        .addHandler(AuthController.registerUser)
        .call(req);
  });

  router.post(Constants.reRegister, (req) {
    return Pipeline()
        .addMiddleware(secretKeyMiddleware())
        .addMiddleware(tokenMiddleware(TokenType.refresh, false))
        .addHandler(AuthController.reActivateUser)
        .call(req);
  });

  router.post(Constants.refresh, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.refresh))
        .addHandler(AuthController.refreshToken)
        .call(req);
  });

  router.post(Constants.events, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.events)
        .call(req);
  });

  router.post(Constants.update, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.update)
        .call(req);
  });

  router.post(Constants.addEvent, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.addEvent)
        .call(req);
  });

  router.post(Constants.addMany, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.addMany)
        .call(req);
  });

  router.delete(Constants.deleteOne, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.deleteOne)
        .call(req);
  });

  router.delete(Constants.deleteMany, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.deleteMany)
        .call(req);
  });

  router.delete(Constants.deleteAll, (req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler(EventsController.deleteAll)
        .call(req);
  });

  router.post(Constants.queueResponse, (req) {
    return Pipeline()
        .addHandler(NotificationsController.sendNotificationToClient)
        .call(req);
  });

  router.post(Constants.toggleNotification, (Request req, String eventId) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler((Request innerReq) {
      return NotificationsController.toggleNotification(innerReq, eventId);
    }).call(req);
  });

  router.post(Constants.pauseResumeNotifications, (Request req) {
    return Pipeline()
        .addMiddleware(tokenMiddleware(TokenType.access))
        .addHandler((Request innerReq) {
      return NotificationsController.pauseResumeNotifications(innerReq);
    }).call(req);
  });

  return router;
}
