import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  bool get isConnected => _channel != null; // ✅ Add this getter

  void connect(String url) {
    if (_channel == null) {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      print("WebSocket connected to $url");
    } else {
      print("WebSocket already connected");
    }
  }

  void send(String data) {
    if (isConnected) {
      _channel!.sink.add(data);
      print("Message sent: $data");
    } else {
      print("Cannot send, WebSocket not connected!");
    }
  }

  Stream get stream {
    if (_channel != null) {
      return _channel!.stream;
    } else {
      throw Exception("WebSocket not connected");
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      print("WebSocket disconnected");
    }
  }
}
