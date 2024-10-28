import 'package:dotenv/dotenv.dart';

class DotEnvService {
  late DotEnv _env;

  DotEnvService() {
    _env = DotEnv(includePlatformEnvironment: true)..load();
  }

  String getEnv(String v) => _env[v]!;
}
