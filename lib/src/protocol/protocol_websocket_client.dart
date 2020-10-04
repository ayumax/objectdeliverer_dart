import 'package:universal_io/io.dart';

import 'protocol_websocket.dart';

/// WebSocket Client protocol
class ProtocolWebSocketClient extends ProtocolWebSocket {
  ProtocolWebSocketClient.fromParam(this.url,
      {this.autoConnectAfterDisconnect});

  Future _connectTask;

  String url = 'ws://127.0.0.1:8080/ws';

  bool autoConnectAfterDisconnect = false;

  bool _isSelfClose = false;

  @override
  Future start() async {
    await super.start();

    // ignore: unawaited_futures
    _startConnect();
  }

  @override
  Future close() async {
    _isSelfClose = true;

    await super.close();

    await _connectTask;
  }

  Future _startConnect() async {
    Future _connect() async {
      _isSelfClose = false;

      webSocket = null;

      while (_isSelfClose == false) {
        try {
          await startConnect(url);

          break;
        } on SocketException {
          // Wait a minute and then try to reconnect.
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    _connectTask = _connect();
    return _connectTask;
  }

  @override
  void onDone() async {
    super.onDone();

    if (_isSelfClose == false && autoConnectAfterDisconnect) {
      // ignore: unawaited_futures
      _startConnect();
    }
  }
}
