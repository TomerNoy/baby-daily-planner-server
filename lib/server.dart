import 'dart:io';

import 'package:myserver/config/constants.dart';
import 'package:myserver/routes/routes.dart';
import 'package:myserver/services/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<void> server({required bool isDebugMode}) async {
  final ip = InternetAddress.anyIPv4;

  await ServiceProvider.init(isDebugMode: isDebugMode);

  // log('Starting server...');

  final call = getRouter().call;

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(call);

  final port = int.parse(Platform.environment['PORT'] ?? Constants.defaultPort);
  try {
    final server = await serve(handler, ip, port);
    loggerService.debug('Server listening on port ${server.port}');
  } catch (e) {
    loggerService.error('Failed to start the server: $e');
  }
}
