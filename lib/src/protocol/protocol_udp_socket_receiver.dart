import 'dart:io';
import 'dart:typed_data';

import 'protocol_ip_Socket.dart';

class ProtocolUdpSocketReceiver extends ProtocolIpSocket {
  int boundPort;
  RawDatagramSocket _udpReceiver;

  @override
  Future<void> startAsync() async {
    _udpReceiver =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, boundPort)
          ..readEventsEnabled = true
          ..writeEventsEnabled = false
          ..listen(_onReceived, onError: _onError, cancelOnError: false);

    dispatchConnected(this);

    startReceive();
  }

  @override
  Future<void> closeAsync() async {
    if (_udpReceiver == null) {
      return;
    }

    _udpReceiver.close();

    await stopReceive();

    _udpReceiver = null;
  }

  @override
  Future<void> sendAsync(Uint8List dataBuffer) async {
    // no send
  }

  Future<void> _onReceived(RawSocketEvent udpEvent) async {
    if (udpEvent == RawSocketEvent.read) {
      await mutex.protect(() async {
        final datagram = _udpReceiver.receive();
        tempReceiveBuffer.add(datagram.data);
      });
    }
  }

  void _onError(Object er) {
    _udpReceiver.close();
    dispatchDisconnected(this);
  }
}
