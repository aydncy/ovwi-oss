import 'dart:convert';
import 'package:shelf/shelf.dart';

Response jsonResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json',
    },
  );
}
