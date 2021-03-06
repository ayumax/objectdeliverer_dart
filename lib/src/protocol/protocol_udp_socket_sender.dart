import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'objectdeliverer_protocol.dart';

/// /// UDP Sender protocol
class ProtocolUdpSocketSender extends ObjectDelivererProtocol {
  ProtocolUdpSocketSender.fromParam(
      String destinationIpAddress, this.destinationPort) {
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

  RawDatagramSocket _udpSender;

  @override
  Future start() async {
    _udpSender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    dispatchConnected(this);
  }

  @override
  Future close() async {
    if (_udpSender == null) {
      return;
    }

    _udpSender.close();

    _udpSender = null;
  }

  @override
  Future send(Uint8List dataBuffer) async {
    if (_udpSender == null) {
      return;
    }

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);
    _udpSender.send(
        sendBuffer, InternetAddress(destinationIpAddress), destinationPort);
  }
}
