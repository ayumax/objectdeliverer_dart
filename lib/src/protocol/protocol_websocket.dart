import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'protocol_ip_socket.dart';

class ProtocolWebSocket extends ProtocolIpSocket {
  ProtocolWebSocket();
  ProtocolWebSocket.fromConnectedSocket(this.webSocket) {
    webSocket!.listen(
      _onReceived,
      onError: _onError,
      onDone: onDone,
      cancelOnError: true,
    );

    dispatchConnected(this);

    startReceive();
  }

  Future<void> startConnect(String url) async {
    webSocket = await WebSocket.connect(url)
      ..listen(
        _onReceived,
        onError: _onError,
        onDone: onDone,
        cancelOnError: true,
      );

    dispatchConnected(this);

    startReceive();
  }

  WebSocket? webSocket;
  bool _selfClose = false;

  @override
  Future<void> start() async {}

  @override
  Future<void> close() async {
    final ws = webSocket;
    if (ws == null) {
      return;
    }

    _selfClose = true;

    await ws.close();

    await stopReceive();

    webSocket = null;
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {
    final ws = webSocket;
    if (ws == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    ws.add(sendBuffer);
  }

  void _onReceived(dynamic receivedBuffer) async {
    await mutex.protect(() async {
      tempReceiveBuffer.add(receivedBuffer as Uint8List);
    });
  }

  void _onError(Object er) async {
    onDone();
  }

  void onDone() async {
    final ws = webSocket;
    if (_selfClose == false && ws != null) {
      await ws.close();

      await stopReceive();

      webSocket = null;
      dispatchDisconnected(this);
    }
  }
}
