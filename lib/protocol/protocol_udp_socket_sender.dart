// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:io';
import 'dart:typed_data';

import 'objectdeliverer_protocol.dart';

class ProtocolUdpSocketSender extends ObjectDelivererProtocol {
  String destinationIpAddress = '127.0.0.1';

  int destinationPort = 0;

  RawDatagramSocket _udpSender;

  @override
  Future<void> startAsync() async {
    _udpSender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    dispatchConnected(this);
  }

  @override
  Future<void> closeAsync() async {
    if (_udpSender == null) {
      return;
    }

    _udpSender.close();

    _udpSender = null;
  }

  @override
  Future<void> sendAsync(Uint8List dataBuffer) async {
    if (_udpSender == null) {
      return;
    }

    _udpSender.send(
        dataBuffer, InternetAddress(destinationIpAddress), destinationPort);
  }
}
