import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'protocol_ip_socket.dart';

class ProtocolWebSocket extends ProtocolIpSocket {
  ProtocolWebSocket();
  ProtocolWebSocket.fromConnectedSocket(this.webSocket) {
    webSocket.listen(_onReceived,
        onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  Future startConnect(String url) async {
    webSocket = await WebSocket.connect(url)
      ..listen(_onReceived,
          onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  WebSocket webSocket;
  bool _selfClose = false;

  @override
  Future start() async {}

  @override
  Future close() async {
    if (webSocket == null) {
      return;
    }

    _selfClose = true;

    await webSocket.close();

    await stopReceive();

    webSocket = null;
  }

  @override
  Future send(Uint8List dataBuffer) async {
    if (webSocket == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    // ignore: unnecessary_cast
    webSocket.add(sendBuffer as List<int>);
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
    if (_selfClose == false && webSocket != null) {
      await webSocket.close();

      await stopReceive();

      webSocket = null;
      dispatchDisconnected(this);
    }
  }
}
