import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'objectdeliverer_protocol.dart';

class ProtocolUdpSocketSender extends ObjectDelivererProtocol {
  ProtocolUdpSocketSender.fromParam(
    String destinationIpAddress,
    this.destinationPort,
  ) {
    this.destinationIpAddress = destinationIpAddress;
  }

  String _destinationIpAddress = '127.0.0.1';
  String get destinationIpAddress => _destinationIpAddress;
  set destinationIpAddress(String newValue) {
    if (newValue.toLowerCase() == 'localhost') {
      _destinationIpAddress = '127.0.0.1';
    } else {
      _destinationIpAddress = newValue;
    }
  }

  int destinationPort = 0;

  RawDatagramSocket? _udpSender;

  @override
  Future<void> start() async {
    _udpSender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    dispatchConnected(this);
  }

  @override
  Future<void> close() async {
    _udpSender?.close();

    _udpSender = null;
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {
    final sender = _udpSender;
    if (sender == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);
    sender.send(
      sendBuffer,
      InternetAddress(destinationIpAddress),
      destinationPort,
    );
  }
}
