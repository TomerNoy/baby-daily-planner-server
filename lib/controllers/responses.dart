import 'dart:convert';

import 'package:myserver/config/constants.dart';
import 'package:shelf/shelf.dart';

class Responses {
  static Response ok([Map<String, dynamic>? map]) {
    return Response.ok(
      headers: Constants.headers,
      jsonEncode(map ?? {'msg': 'ok'}),
    );
  }

  static Response serverError(String msg) {
    return Response.internalServerError(
      headers: Constants.headers,
      body: jsonEncode({'error': msg}),
    );
  }

  static Response forbidden(String msg) {
    return Response.forbidden(
      headers: Constants.headers,
      jsonEncode({'error': msg}),
    );
  }

  static Response notFound(String msg) {
    return Response.notFound(
      headers: Constants.headers,
      jsonEncode({'error': msg}),
    );
  }

  static Response badRequest(String msg) {
    return Response.badRequest(
      headers: Constants.headers,
      body: jsonEncode({'error': msg}),
    );
  }
}
