import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'services.dart';

enum TokenType { access, refresh }

class TokenService {
  String generateToken(String userId, String secret, TokenType type) {
    final now = DateTime.now();
    final duration =
        type == TokenType.refresh ? Duration(days: 30) : Duration(hours: 1);
    final expiry = now.add(duration);

    final claimSet = JwtClaim(
      issuer: 'baby_daily_planner',
      subject: userId,
      expiry: expiry,
      issuedAt: now,
      payload: {'type': type.name},
    );

    loggerService.debug(
      'generated token for $userId with type ${type.name}, expiry: $expiry',
    );

    return issueJwtHS256(claimSet, secret);
  }
}
