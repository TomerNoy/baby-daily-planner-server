import 'package:get_it/get_it.dart';
import 'package:myserver/services/encrypt_service.dart';
import 'package:myserver/services/notification_service.dart';
import 'package:myserver/services/token_service.dart';
import 'mongo_service.dart';
import 'dotenv_service.dart';
import 'logger_service.dart';

class ServiceProvider {
  static final _getIt = GetIt.instance;

  static Future<void> init({
    required bool isDebugMode,
  }) async {
    try {
      // logger
      _getIt.registerSingleton(LoggerService(isDebugMode: isDebugMode));

      // DotEnv
      _getIt.registerSingleton(DotEnvService());

      // notifications
      _getIt.registerSingletonAsync(
        () async {
          final notificationService = NotificationService();
          await notificationService.init();
          return notificationService;
        },
      );

      await _getIt.isReady<NotificationService>();

      // mongo
      _getIt.registerSingletonAsync(
        () async {
          final mongoService = MongoService(dotEnvService);
          await mongoService.connect();
          return mongoService;
        },
      );

      // token
      _getIt.registerLazySingleton(() => TokenService());

      final privateKey = dotEnvService.getEnv('PRIVATE_KEY');
      // encrypt
      _getIt.registerLazySingleton(() => DecryptionService(privateKey));

      await _getIt.allReady();
      loggerService.debug('services initialized');
    } catch (e, st) {
      loggerService.error('services error', e, st);
    }
  }
}

DotEnvService get dotEnvService {
  return ServiceProvider._getIt.get<DotEnvService>();
}

MongoService get mongoService {
  return ServiceProvider._getIt.get<MongoService>();
}

LoggerService get loggerService {
  return ServiceProvider._getIt.get<LoggerService>();
}

TokenService get tokenService {
  return ServiceProvider._getIt.get<TokenService>();
}

DecryptionService get decryptionService {
  return ServiceProvider._getIt.get<DecryptionService>();
}

NotificationService get notificationService {
  return ServiceProvider._getIt.get<NotificationService>();
}
