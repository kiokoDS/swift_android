import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  
  Future<void> connect(String url) async {
    try {
      print('Connecting to WebSocket: $url');
      
      // Use IOWebSocketChannel.connect instead of WebSocketChannel.connect
      final wsUrl = Uri.parse(url);
      final socket = await WebSocket.connect(wsUrl.toString());
      _channel = IOWebSocketChannel(socket);
      
      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection error: $e');
      _channel = null;
      rethrow;
    }
  }
  
  void send(String data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(data);
        print('WebSocket sent: $data');
      } catch (e) {
        print('WebSocket send error: $e');
      }
    } else {
      print('WebSocket not connected, cannot send data');
    }
  }
  
  Stream? get stream => _channel?.stream;
  
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
      print('WebSocket disconnected');
    }
  }
}