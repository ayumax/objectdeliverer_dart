import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol_ip_Socket.dart';

class ProtocolTcpIpSocket extends ProtocolIpSocket {
  ProtocolTcpIpSocket();
  ProtocolTcpIpSocket.fromConnectedSocket(this.ipClient) {
    ipClient.listen(_onReceived,
        onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  Future startConnect(String ipAddress, int port) async {
    ipClient = await Socket.connect(ipAddress, port)
      ..listen(_onReceived,
          onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  Socket ipClient;
  bool _selfClose = false;

  @override
  Future startAsync() async {}

  @override
  Future closeAsync() async {
    if (ipClient == null) {
      return;
    }

    _selfClose = true;

    await ipClient.close();
    ipClient.destroy();

    await stopReceive();

    ipClient = null;
  }

  @override
  Future sendAsync(Uint8List dataBuffer) async {
    if (ipClient == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    ipClient.add(sendBuffer);
    return ipClient.flush();
  }

  Future _onReceived(Uint8List receivedBuffer) async {
    await mutex.protect(() async {
      tempReceiveBuffer.add(receivedBuffer);
    });
  }

  void _onError(Object er) async {
    onDone();
  }

  void onDone() async {
    if (_selfClose == false && ipClient != null) {
      await ipClient.close();
      if (ipClient != null) {
        ipClient.destroy();
      }

      await stopReceive();

      ipClient = null;
      dispatchDisconnected(this);
    }
  }
}
