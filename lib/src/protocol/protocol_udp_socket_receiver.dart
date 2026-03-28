import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'protocol_ip_socket.dart';

class ProtocolUdpSocketReceiver extends ProtocolIpSocket {
  ProtocolUdpSocketReceiver.fromParam(this.boundPort);

  int boundPort;
  RawDatagramSocket? _udpReceiver;

  @override
  Future<void> start() async {
    _udpReceiver =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, boundPort)
          ..readEventsEnabled = true
          ..writeEventsEnabled = false
          ..listen(_onReceived, onError: _onError, cancelOnError: true);

    dispatchConnected(this);

    startReceive();
  }

  @override
  Future<void> close() async {
    _udpReceiver?.close();

    await stopReceive();

    _udpReceiver = null;
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {}

  Future<void> _onReceived(RawSocketEvent udpEvent) async {
    final receiver = _udpReceiver;
    if (udpEvent == RawSocketEvent.read && receiver != null) {
      final datagram = receiver.receive();
      if (datagram != null) {
        await mutex.protect(() async {
          tempReceiveBuffer.add(datagram.data);
        });
      }
    }
  }

  void _onError(Object er) {
    _udpReceiver?.close();
    dispatchDisconnected(this);
  }
}
