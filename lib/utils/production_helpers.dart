import 'dart:convert';
import 'dart:io';
void logInfo(String m) { print(jsonEncode({'t': DateTime.now(), 'm': m})); }
String health() { return jsonEncode({'status':'ok', 'v':'0.2.0'}); }








