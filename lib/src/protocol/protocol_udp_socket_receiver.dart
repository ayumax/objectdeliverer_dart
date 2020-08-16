import 'dart:io';
import 'dart:typed_data';

import 'protocol_ip_socket.dart';

class ProtocolUdpSocketReceiver extends ProtocolIpSocket {
  ProtocolUdpSocketReceiver.fromParam(this.boundPort);

  int boundPort;
  RawDatagramSocket _udpReceiver;

  @override
  Future start() async {
    _udpReceiver =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, boundPort)
          ..readEventsEnabled = true
          ..writeEventsEnabled = false
          ..listen(_onReceived, onError: _onError, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  @override
  Future close() async {
    if (_udpReceiver == null) {
      return;
    }

    _udpReceiver.close();

    await stopReceive();

    _udpReceiver = null;
  }

  @override
  Future send(Uint8List dataBuffer) async {
    // no send
  }

  Future _onReceived(RawSocketEvent udpEvent) async {
    if (udpEvent == RawSocketEvent.read) {
      final datagram = _udpReceiver.receive();
      if (datagram != null) {
        await mutex.protect(() async {
          tempReceiveBuffer.add(datagram.data);
        });
      }
    }
  }

  void _onError(Object er) {
    _udpReceiver.close();
    dispatchDisconnected(this);
  }
}
