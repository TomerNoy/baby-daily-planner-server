import 'dart:convert';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:myserver/services/services.dart';
import 'package:shelf/shelf.dart';

class GlobalFunctions {
  static String? extractUserId(Request req) {
    try {
      final jwtClaim = req.context['jwtClaim'] as JwtClaim;
      return jwtClaim.subject!;
    } catch (e) {
      loggerService.error('extractUserId error $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> extractBody(Request req) async {
    try {
      final bodyRaw = await req.readAsString();
      return jsonDecode(bodyRaw) as Map<String, dynamic>;
    } catch (e) {
      loggerService.error('extractBody error $e');
      return null;
    }
  }

}
