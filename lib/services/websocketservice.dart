import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void send(String data) {
    _channel?.sink.add(data);
  }

  Stream get stream => _channel!.stream;

  void disconnect() {
    _channel?.sink.close();
  }
}
