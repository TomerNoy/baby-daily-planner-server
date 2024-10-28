import 'dart:io';
import 'package:synchronized/synchronized.dart';
import 'package:watcher/watcher.dart';

final lock = Lock();

Future<void> main() async {
  var watcher = DirectoryWatcher('lib');
  Process? serverProcess;

  Future<void> startServer() async {
    await lock.synchronized(() async {
      if (serverProcess != null) {
        serverProcess?.kill();
        await serverProcess?.exitCode;
        print('server process terminated.');
      }

      try {
        serverProcess = await Process.start(
          'dart',
          ['run', 'bin/main.dart', '--debug'],
        );
        print('Server process started.');
      } catch (e) {
        print('Failed to start the server: $e');
      }

      serverProcess!
        ..stdout.transform(SystemEncoding().decoder).listen((data) {
          print(data);
        })
        ..stderr.transform(SystemEncoding().decoder).listen((data) {
          print('Error: $data');
        });
    });
  }

  await startServer();

  watcher.events.listen((event) async {
    print('File changed: ${event.path}');
    await startServer();
  });

  print('Watching for file changes in the "lib" directory...');
}
