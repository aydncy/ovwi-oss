import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {
  late WebSocketChannel _channel;
  final StreamController<Map<String, dynamic>> _eventController = 
    StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel.stream.listen(
        (message) {
          try {
            final event = Map<String, dynamic>.from(
              Uri.splitQueryString(message) as Map<String, dynamic>,
            );
            _eventController.add(event);
          } catch (e) {
            print('Error parsing message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _eventController.addError(error);
        },
        onDone: () {
          print('WebSocket disconnected');
          _eventController.close();
        },
      );
      
      print('✅ WebSocket connected to $url');
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _eventController.addError(e);
    }
  }

  Future<void> sendEvent(Map<String, dynamic> event) async {
    try {
      final message = event.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
      _channel.sink.add(message);
    } catch (e) {
      print('Error sending event: $e');
    }
  }

  Future<void> disconnect() async {
    await _channel.sink.close();
    await _eventController.close();
    print('✅ WebSocket disconnected');
  }
}
