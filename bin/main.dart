import 'package:myserver/server.dart';

void main(List<String> args) async {
  bool isDebugMode = args.contains('--debug');

  if (isDebugMode) {
    print('Running in debug mode');
  } else {
    print('Running in production mode');
  }
  await server(isDebugMode: isDebugMode);
}
