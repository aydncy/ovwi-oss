import 'dart:async';
import 'bin/server_v3.dart';

void main() async {
  print('OVWI Server v3.0 - Local Mode');
  print('Database: In-Memory (No PostgreSQL)');
  print('Port: 8081');
  print('');
  print('Production deployment: docker-compose -f docker-compose.prod.yml up -d');
}
