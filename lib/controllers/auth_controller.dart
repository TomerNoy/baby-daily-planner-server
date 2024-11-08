import 'package:myserver/controllers/global_functions.dart';
import 'package:myserver/controllers/responses.dart';
import 'package:myserver/services/services.dart';
import 'package:myserver/services/token_service.dart';
import 'package:shelf/shelf.dart';

class AuthController {
  /// requires only secret,
  /// returns access token and refresh token (userId inside).
  static Future<Response> registerUser(Request req) async {
    // create user

    final userModel = await mongoService.addNewUser();
    if (userModel == null) {
      return Responses.serverError('creating user error');
    }
    return _returnTokens(userModel.idString);
  }

  /// reactivates expired tokens by validating token and secret.
  /// returns access token and refresh token (userId inside).
  static Future<Response> reActivateUser(Request req) async {
    try {
      final userId = GlobalFunctions.extractUserId(req);
      if (userId == null) {
        return Responses.forbidden('Invalid refresh token');
      }

      final userExists = await mongoService.checkIfUserExists(userId);
      if (!userExists) {
        return Responses.forbidden('User not found');
      }

      // return tokens
      return _returnTokens(userId);
    } catch (e, st) {
      loggerService.error('_reActivateUser error $e, $st');
      return Responses.forbidden('Invalid refresh token');
    }
  }

  /// refreshes both tokens by refresh token
  static Future<Response> refreshToken(Request req) async {
    final userId = GlobalFunctions.extractUserId(req);
    if (userId == null) {
      return Responses.forbidden('Invalid refresh token');
    }

    return _returnTokens(userId);
  }

  static Response _returnTokens(String userId) {
    loggerService.debug('generating tokens for user $userId');
    try {
      final secret = dotEnvService.getEnv('SECRET_KEY');
      final newAccessToken =
          tokenService.generateToken(userId, secret, TokenType.access);
      final newRefreshToken =
          tokenService.generateToken(userId, secret, TokenType.refresh);
      return Responses.ok({
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      });
    } catch (e) {
      loggerService.error('_returnTokens error $e');
      return Responses.serverError('Failed to generate tokens');
    }
  }
}
