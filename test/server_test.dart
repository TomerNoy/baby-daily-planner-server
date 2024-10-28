import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:http/http.dart' as http;

void main() {
  late String accessToken;
  late String refreshToken;
  final List<String> eventsId = [];

  final port = '8080';
  final host = 'http://localhost:$port';
  final secret =
      '1557fa5e928c9b9f301de83fcb436652fe6369cf275a230cfafefb2c0a3540a7';
  late String userId;
  late Process p;

  setUp(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/main.dart'],
      environment: {'PORT': port},
    );

// Convert stdout and stderr streams to broadcast streams
    final stdoutStream = p.stdout.transform(utf8.decoder).asBroadcastStream();
    final stderrStream = p.stderr.transform(utf8.decoder).asBroadcastStream();

    // Listen to stdout and stderr
    stdoutStream.listen((data) {
      print('stdout: $data');
    });

    stderrStream.listen((data) {
      print('stderr: $data');
    });

    // Wait for the server to be ready by waiting for the first line from stdout
    await stdoutStream.first;

    // Give additional time for the server to be ready (optional)
    await Future.delayed(Duration(seconds: 5));
  });

  tearDown(() => p.kill());

  test('register', () async {
    final response = await post(Uri.parse('$host/register?secret=$secret'));
    expect(response.statusCode, 200);
    final body = response.body;
    final responseData = jsonDecode(body);

    expect(responseData['accessToken'], isNotNull);
    expect(responseData['refreshToken'], isNotNull);

    // Save tokens for future tests
    accessToken = responseData['accessToken'];
    refreshToken = responseData['refreshToken'];

    print('accessToken $accessToken');
    print('refreshToken $refreshToken');

    final claimSetAccess = verifyJwtHS256Signature(accessToken, secret);
    final claimSetRefresh = verifyJwtHS256Signature(refreshToken, secret);

    final accessUserId = claimSetAccess.subject;
    final refreshUserId = claimSetRefresh.subject;
    expect(accessUserId, isNotNull);
    expect(accessUserId, isNotEmpty);
    expect(accessUserId, equals(refreshUserId));

    userId = accessUserId!;

    print('userId: $userId');
  });

  test('addEvent1', () async {
    final event = {
      'name': 'Test Event1',
      'time': '12:30',
    };

    final body = jsonEncode({'event': event});

    final response = await http.post(
      Uri.parse('$host/addEvent'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    expect(response.statusCode, 200);
    final responseData = jsonDecode(response.body);

    print('eventId: ${responseData['eventId']}');

    eventsId.add(responseData['eventId']);

    expect(eventsId, isNotEmpty);
  });

  test('addEvent2', () async {
    await Future.delayed(Duration(seconds: 1));
    final event = {
      'name': 'Test Event2',
      'time': '09:30',
    };

    final body = jsonEncode({'event': event});

    final response = await http.post(
      Uri.parse('$host/addEvent'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    expect(response.statusCode, 200);
    final responseData = jsonDecode(response.body);

    print('eventId: ${responseData['eventId']}');

    eventsId.add(responseData['eventId']);

    expect(eventsId, isNotEmpty);
  });

  test('getEvents', () async {
    await Future.delayed(Duration(seconds: 1));
    final response = await http.get(
      Uri.parse('$host/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    expect(response.statusCode, 200);

    final responseData = jsonDecode(response.body);

    print('responseData $responseData');

    final events = responseData['events'];

    expect(events, isA<List>());

    print('events $events ${events.runtimeType}');
  });
}
