import 'package:postgres/postgres.dart';
import '../config/env.dart';

class DB {
  static Connection? _connection;

  static Future<Connection> get connection async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }

    _connection = await Connection.open(
      Endpoint(
        host: Env.dbHost,
        port: Env.dbPort,
        database: Env.dbName,
        username: Env.dbUser,
        password: Env.dbPassword,
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    return _connection!;
  }
}
