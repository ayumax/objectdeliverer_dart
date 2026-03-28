import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'protocol_ip_socket.dart';

class ProtocolTcpIpSocket extends ProtocolIpSocket {
  ProtocolTcpIpSocket();
  ProtocolTcpIpSocket.fromConnectedSocket(this.ipClient) {
    ipClient!.listen(
      _onReceived,
      onError: _onError,
      onDone: onDone,
      cancelOnError: true,
    );

    dispatchConnected(this);

    startReceive();
  }

  Future<void> startConnect(String ipAddress, int port) async {
    final ipAddressValue = ipAddress.toLowerCase() == 'localhost'
        ? InternetAddress.loopbackIPv4
        : InternetAddress(ipAddress);

    ipClient = await Socket.connect(ipAddressValue, port)
      ..listen(
        _onReceived,
        onError: _onError,
        onDone: onDone,
        cancelOnError: true,
      );

    dispatchConnected(this);

    startReceive();
  }

  Socket? ipClient;
  bool _selfClose = false;

  @override
  Future<void> start() async {}

  @override
  Future<void> close() async {
    final client = ipClient;
    if (client == null) {
      return;
    }

    _selfClose = true;

    await client.close();
    client.destroy();

    await stopReceive();

    ipClient = null;
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {
    final client = ipClient;
    if (client == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    client.add(sendBuffer);
    return client.flush();
  }

  Future<void> _onReceived(Uint8List receivedBuffer) async {
    await mutex.protect(() async {
      tempReceiveBuffer.add(receivedBuffer);
    });
  }

  void _onError(Object er) async {
    onDone();
  }

  void onDone() async {
    final client = ipClient;
    if (_selfClose == false && client != null) {
      await client.close();
      client.destroy();

      await stopReceive();

      ipClient = null;
      dispatchDisconnected(this);
    }
  }
}
