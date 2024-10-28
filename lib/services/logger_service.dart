import 'package:logger/logger.dart';

const String debugColor = '\x1B[32m';
const String infoColor = '\x1B[36m';
const String errorColor = '\x1B[31m';
const String warningColor = '\x1B[33m';
const String wtfColor = '\x1B[35m';
const String resetColor = '\u001b[0m';

class LoggerService {
  LoggerService({
    required bool isDebugMode,
  }) {
    _isDebugMode = isDebugMode;

    if (isDebugMode) return;
    _logger = Logger(
      printer: _ColoredLogPrinter(),
      output: ConsoleOutput(),
      filter: DevelopmentFilter(),
    );
  }

  late Logger _logger;
  late bool _isDebugMode;

  void debug(String message) {
    if (_isDebugMode) {
      print('${debugColor}DEBUG: $message$resetColor');
      return;
    }
    _logger.d(message);
  }

  void info(String message) {
    if (_isDebugMode) {
      print('${infoColor}INFO: $message$resetColor');
      return;
    }
    _logger.i(message);
  }

  void warning(String message) {
    if (_isDebugMode) {
      print('${warningColor}WARNING: $message$resetColor');
      return;
    }
    _logger.w(message);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      print(
          '${errorColor}ERROR: $message, error: $error, stackTrace: $stackTrace$resetColor');
      return;
    }
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(String message) {
    if (_isDebugMode) {
      print('${wtfColor}WTF: $message$resetColor');
      return;
    }
    _logger.f(message);
  }
}

class _ColoredLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final time = '${event.time.hour}:${event.time.minute}:${event.time.second}';
    final level = event.level;
    final name = level.name;
    final msg = event.message;
    final e = event.error;
    final st = event.stackTrace;

    final color = switch (level) {
      Level.debug => debugColor,
      Level.info => infoColor,
      Level.warning => warningColor,
      Level.error => errorColor,
      Level.fatal => wtfColor,
      _ => debugColor,
    };

    final output = ['$color$name $time: $msg$resetColor'];

    if (event.error != null) {
      output.add('$errorColor$e$resetColor');
    }

    if (st != null) {
      output.add('$errorColor$st$resetColor');
    }

    return output;
  }
}
