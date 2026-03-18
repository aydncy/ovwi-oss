import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';

PostgreSQLConnection? conn;

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  try {
    conn = PostgreSQLConnection(
      Platform.environment['DB_HOST'] ?? '',
      int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      Platform.environment['DB_NAME'] ?? '',
      username: Platform.environment['DB_USER'],
      password: Platform.environment['DB_PASS'],
      useSSL: true,
    );

    await conn!.open();
    print("DB CONNECTED");
  } catch (e) {
    print("DB FAILED");
    conn = null;
  }

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
  await io.serve(handler, '0.0.0.0', port);
  print('Server running');
}

Future<Response> _router(Request req) async {
  final path = req.url.pathSegments;

  if (req.url.path == 'health') {
    return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
  }

  if (path.length == 2 && path[0] == 'verify') {
    final apiKey = path[1];

    if (conn == null) return Response.ok('NO_DB');

    final result = await conn!.query(
      'SELECT usage_count, usage_limit FROM api_keys WHERE api_key = @key',
      substitutionValues: {'key': apiKey},
    );

    if (result.isEmpty) return Response.notFound('invalid');

    final usage = result.first[0] as int;
    final limit = result.first[1] as int;

    if (usage >= limit) return Response.forbidden('limit reached');

    await conn!.query(
      'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
      substitutionValues: {'key': apiKey},
    );

    return Response.ok('ok');
  }

  if (req.url.path == 'payment/success') {
    final token = req.url.queryParameters['token'] ?? '';

    if (token.isEmpty) return Response(400, body: 'missing token');
    if (conn == null) return Response.ok('NO_DB');

    try {
      final tokenCheck = await conn!.query(
        'SELECT plan, used FROM purchase_tokens WHERE token = @token LIMIT 1',
        substitutionValues: {'token': token},
      );

      if (tokenCheck.isEmpty) return Response.forbidden('invalid token');

      final used = tokenCheck.first[1] as bool;
      final plan = tokenCheck.first[0] as String;

      if (used) return Response.forbidden('already used');

      final apiKey = _generateApiKey();

      int limit = 100;
      if (plan == 'pro') limit = 10000;
      if (plan == 'ultra') limit = 100000;

      await conn!.query(
        '''
        INSERT INTO api_keys (api_key, plan, usage_count, usage_limit, is_active)
        VALUES (@key, @plan, 0, @limit, true)
        ''',
        substitutionValues: {
          'key': apiKey,
          'plan': plan,
          'limit': limit,
        },
      );

      await conn!.query(
        'UPDATE purchase_tokens SET used = true WHERE token = @token',
        substitutionValues: {'token': token},
      );

      return Response.ok(
        "{\"ok\":true,\"api_key\":\"" + apiKey + "\",\"plan\":\"" + plan + "\"}",
        headers: {"Content-Type": "application/json"},
      );
    } catch (e) {
      return Response.ok('FAIL');
    }
  }

  if (req.url.path == 'gumroad/webhook' && req.method == 'POST') {
  if (conn == null) return Response.ok('NO_DB');

  final body = await req.readAsString();
  final data = Uri.splitQueryString(body);

  final saleId = data['sale_id'] ?? '';
  final email = data['email'] ?? '';
  final plan = (data['variants'] ?? 'pro').toLowerCase();

  if (saleId.isEmpty) return Response(400, body: 'no sale');

  final exists = await conn!.query(
    'SELECT token FROM gumroad_sales WHERE sale_id = @id LIMIT 1',
    substitutionValues: {'id': saleId},
  );

  if (exists.isNotEmpty) {
    final t = exists.first[0];
    return Response.ok('<h1>Already activated</h1><p>Your key was already generated.</p>', headers: {'Content-Type': 'text/html'});
  }

  final apiKey = _generateApiKey();

  int limit = 100;
  if (plan == 'pro') limit = 10000;
  if (plan == 'ultra') limit = 100000;

  await conn!.query(
    '''
    INSERT INTO api_keys (api_key, plan, usage_count, usage_limit, is_active)
    VALUES (@key, @plan, 0, @limit, true)
    ''',
    substitutionValues: {
      'key': apiKey,
      'plan': plan,
      'limit': limit,
    },
  );

  await conn!.query(
    'INSERT INTO gumroad_sales (sale_id,email,plan,token) VALUES (@id,@e,@p,@t)',
    substitutionValues: {'id': saleId,'e': email,'p': plan,'t': apiKey},
  );

  return Response.ok(
    '<h1>Your API Key</h1><p style=""font-size:20px;"">' + apiKey + '</p>',
    headers: {'Content-Type': 'text/html'},
  );
}

if (req.url.path == 'dashboard') {
  if (conn == null) return Response.ok('NO_DB');

  final key = req.url.queryParameters['key'] ?? '';

  if (key.isEmpty) {
    return Response.ok('<h1>Missing API Key</h1>', headers: {'Content-Type': 'text/html'});
  }

  try {
    final result = await conn!.query(
      'SELECT usage_count, usage_limit, plan FROM api_keys WHERE api_key = @key LIMIT 1',
      substitutionValues: {'key': key},
    );

    if (result.isEmpty) {
      return Response.ok('<h1>Invalid API Key</h1>', headers: {'Content-Type': 'text/html'});
    }

    final usage = result.first[0];
    final limit = result.first[1];
    final plan = result.first[2];

    final percent = ((usage / limit) * 100).toStringAsFixed(2);

    return Response.ok(
      '<h1>OVWI Dashboard</h1>'
      '<p><b>API Key:</b> ' + key + '</p>'
      '<p><b>Plan:</b> ' + plan.toString() + '</p>'
      '<p><b>Usage:</b> ' + usage.toString() + ' / ' + limit.toString() + '</p>'
      '<p><b>Usage %:</b> ' + percent + '%</p>',
      headers: {'Content-Type': 'text/html'},
    );
  } catch (e) {
    return Response.ok('ERROR');
  }
}

return Response.notFound('not found');
}

String _generateApiKey() {
  final rand = (DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(999999)).toString();
  return "ovwi_live_" + rand;
}



