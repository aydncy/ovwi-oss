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

    final ip = _clientIp(req);

    final limited = await _hitIpRateLimit(ip, 60, 120);
    if (limited) {
      return Response(
        429,
        body: 'rate limit exceeded',
        headers: {'Content-Type': 'text/plain'},
      );
    }

    final result = await conn!.query(
      'SELECT usage_count, usage_limit, is_active FROM api_keys WHERE api_key = @key LIMIT 1',
      substitutionValues: {'key': apiKey},
    );

    if (result.isEmpty) return Response.notFound('invalid');

    final usage = result.first[0] as int;
    final limit = result.first[1] as int;
    final isActive = result.first[2] as bool;

    if (!isActive) return Response.forbidden('inactive');
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
      return Response.ok(
        '<h1>Already activated</h1><p>Your key was already generated.</p>',
        headers: {'Content-Type': 'text/html'},
      );
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
      substitutionValues: {'id': saleId, 'e': email, 'p': plan, 't': apiKey},
    );

    return Response.ok(
      '<h1>Your API Key</h1><p style="font-size:20px;">' + apiKey + '</p><p><a href="/dashboard?key=' + apiKey + '">Open dashboard</a></p>',
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
        'SELECT usage_count, usage_limit, plan, is_active FROM api_keys WHERE api_key = @key LIMIT 1',
        substitutionValues: {'key': key},
      );

      if (result.isEmpty) {
        return Response.ok('<h1>Invalid API Key</h1>', headers: {'Content-Type': 'text/html'});
      }

      final usage = result.first[0] as int;
      final limit = result.first[1] as int;
      final plan = result.first[2].toString();
      final isActive = result.first[3] as bool;
      final percent = limit == 0 ? '0.00' : ((usage / limit) * 100).toStringAsFixed(2);
      final status = isActive ? 'active' : 'inactive';

      return Response.ok(
        '<h1>OVWI Dashboard</h1>'
        '<p><b>API Key:</b> ' + key + '</p>'
        '<p><b>Plan:</b> ' + plan + '</p>'
        '<p><b>Status:</b> ' + status + '</p>'
        '<p><b>Usage:</b> ' + usage.toString() + ' / ' + limit.toString() + '</p>'
        '<p><b>Usage %:</b> ' + percent + '%</p>',
        headers: {'Content-Type': 'text/html'},
      );
    } catch (e) {
      return Response.ok('ERROR');
    }
  }

  if (req.url.path == 'verify-key' && req.method == 'GET') {
  final apiKey = req.url.queryParameters['key'] ?? '';

  if (apiKey.isEmpty) return Response(400, body: 'missing key');
  if (conn == null) return Response.ok('NO_DB');

  try {
    final keyData = await conn!.query(
      'SELECT usage_count, usage_limit, plan, is_active FROM api_keys WHERE api_key = @key LIMIT 1',
      substitutionValues: {'key': apiKey},
    );

    if (keyData.isEmpty) return Response.notFound('invalid');

    final usage = keyData.first[0] as int;
    final limit = keyData.first[1] as int;
    final plan = keyData.first[2].toString();
    final isActive = keyData.first[3] as bool;

    if (!isActive) return Response.forbidden('inactive');
    if (usage >= limit) return Response.forbidden('limit reached');

    final rateLimited = await _hitKeyRateLimit(apiKey, plan);
    if (rateLimited) return Response(429, body: 'rate limited');

    await conn!.query(
      'UPDATE api_keys SET usage_count = usage_count + 1 WHERE api_key = @key',
      substitutionValues: {'key': apiKey},
    );

    return Response.ok('ok');
  } catch (e) {
    return Response.ok('ERROR');
  }
}

return Response.notFound('not found');
}

Future<bool> _hitIpRateLimit(String ip, int windowSeconds, int maxRequests) async {
  if (conn == null) return false;

  final result = await conn!.query(
    'SELECT request_count, window_start FROM ip_rate_limits WHERE ip = @ip LIMIT 1',
    substitutionValues: {'ip': ip},
  );

  final now = DateTime.now().toUtc();

  if (result.isEmpty) {
    await conn!.query(
      'INSERT INTO ip_rate_limits (ip, request_count, window_start) VALUES (@ip, 1, @now)',
      substitutionValues: {'ip': ip, 'now': now},
    );
    return false;
  }

  final count = result.first[0] as int;
  final windowStart = (result.first[1] as DateTime).toUtc();
  final diff = now.difference(windowStart).inSeconds;

  if (diff >= windowSeconds) {
    await conn!.query(
      'UPDATE ip_rate_limits SET request_count = 1, window_start = @now WHERE ip = @ip',
      substitutionValues: {'ip': ip, 'now': now},
    );
    return false;
  }

  if (count >= maxRequests) {
    return true;
  }

  await conn!.query(
    'UPDATE ip_rate_limits SET request_count = request_count + 1 WHERE ip = @ip',
    substitutionValues: {'ip': ip},
  );

  return false;
}

String _clientIp(Request req) {
  final forwarded = req.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.trim().isNotEmpty) {
    return forwarded.split(',').first.trim();
  }

  final realIp = req.headers['x-real-ip'];
  if (realIp != null && realIp.trim().isNotEmpty) {
    return realIp.trim();
  }

  return 'unknown';
}

String _generateApiKey() {
  final rand = (DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(999999)).toString();
  return "ovwi_live_" + rand;
}

Future<bool> _hitKeyRateLimit(String key, String plan) async {
  if (conn == null) return false;

  int max = 10;
  if (plan == 'pro') max = 120;
  if (plan == 'ultra') max = 300;

  final result = await conn!.query(
    'SELECT request_count, window_start FROM key_rate_limits WHERE api_key = @key LIMIT 1',
    substitutionValues: {'key': key},
  );

  final now = DateTime.now().toUtc();

  if (result.isEmpty) {
    await conn!.query(
      'INSERT INTO key_rate_limits (api_key, request_count, window_start) VALUES (@key, 1, @now)',
      substitutionValues: {'key': key, 'now': now},
    );
    return false;
  }

  final count = result.first[0] as int;
  final windowStart = (result.first[1] as DateTime).toUtc();
  final diff = now.difference(windowStart).inSeconds;

  if (diff >= 60) {
    await conn!.query(
      'UPDATE key_rate_limits SET request_count = 1, window_start = @now WHERE api_key = @key',
      substitutionValues: {'key': key, 'now': now},
    );
    return false;
  }

  if (count >= max) return true;

  await conn!.query(
    'UPDATE key_rate_limits SET request_count = request_count + 1 WHERE api_key = @key',
    substitutionValues: {'key': key},
  );

  return false;
}

