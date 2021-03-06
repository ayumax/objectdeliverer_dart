import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'protocol_ip_socket.dart';

class ProtocolTcpIpSocket extends ProtocolIpSocket {
  ProtocolTcpIpSocket();
  ProtocolTcpIpSocket.fromConnectedSocket(this.ipClient) {
    ipClient.listen(_onReceived,
        onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  Future startConnect(String ipAddress, int port) async {
    final ipAddressValue = ipAddress.toLowerCase() == 'localhost'
        ? InternetAddress.loopbackIPv4
        : ipAddress;

    ipClient = await Socket.connect(ipAddressValue, port)
      ..listen(_onReceived,
          onError: _onError, onDone: onDone, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  Socket ipClient;
  bool _selfClose = false;

  @override
  Future start() async {}

  @override
  Future close() async {
    if (ipClient == null) {
      return;
    }

    _selfClose = true;

    await ipClient.close();
    if (ipClient != null) {
      ipClient.destroy();
    }

    await stopReceive();

    ipClient = null;
  }

  @override
  Future send(Uint8List dataBuffer) async {
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
