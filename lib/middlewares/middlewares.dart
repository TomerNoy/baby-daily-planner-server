import 'dart:convert';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:shelf/shelf.dart';
import '../services/services.dart';
import '../services/token_service.dart';

// Middleware for secret validation in URL
Middleware secretKeyMiddleware() {
  return (Handler handler) {
    return (Request request) {
      final secret = dotEnvService.getEnv('SECRET_KEY');
      final secretKey = request.url.queryParameters['secret'];
      if (secretKey == secret) {
        return handler(request);
      } else {
        loggerService.debug('secretKey: $secretKey != secret: $secret');
        return _forbidden('Forbidden');
      }
    };
  };
}

Middleware tokenMiddleware(TokenType type, [checkExpiration = true]) {
  return (Handler handler) {
    return (Request request) {
      final authHeader = request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        loggerService.error('token was missing or invalid');
        return _forbidden('Invalid token');
      }

      final token = authHeader.substring(7);
      final secret = dotEnvService.getEnv('SECRET_KEY');

      try {
        final claimSet = verifyJwtHS256Signature(token, secret);

        // claims validations
        final userId = claimSet.subject;
        final reqTokenType = claimSet.payload['type'];
        if (reqTokenType != type.name || userId == null) {
          loggerService.error(
            'token had a wrong type, token type: $reqTokenType, required type: ${type.name}',
          );
          return _forbidden('Invalid token');
        }

        // Check if the token is expired
        if (checkExpiration &&
            claimSet.expiry != null &&
            DateTime.now().isAfter(claimSet.expiry!)) {
          loggerService.error('token expired');
          return _forbidden('Invalid token');
        }
        final updatedRequest = request.change(context: {'jwtClaim': claimSet});
        return handler(updatedRequest);
      } catch (e) {
        loggerService.error('token validation had error $e');
        return _forbidden('Invalid token');
      }
    };
  };
}

Response _forbidden(String msg) {
  return Response.forbidden(
    headers: {'Content-Type': 'application/json'},
    jsonEncode({'error': msg}),
  );
}
