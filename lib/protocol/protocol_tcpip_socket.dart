// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol_ip_Socket.dart';

class ProtocolTcpIpSocket extends ProtocolIpSocket {
  ProtocolTcpIpSocket();
  ProtocolTcpIpSocket.fromConnectedSocket(this.ipClient) {
    ipClient.listen(_onReceived, onError: _onError, cancelOnError: false);
    dispatchConnected(this);

    startReceive();
  }

  Future<void> startConnect(String ipAddress, int port) async {
    ipClient = await Socket.connect(ipAddress, port)
      ..listen(_onReceived, onError: _onError, cancelOnError: false);

    dispatchConnected(this);

    startReceive();
  }

  Socket ipClient;

  @override
  Future<void> startAsync() async {}

  @override
  Future<void> closeAsync() async {
    if (ipClient == null) {
      return;
    }

    await ipClient.close();

    await stopReceive();

    ipClient = null;
  }

  @override
  Future<void> sendAsync(Uint8List dataBuffer) async {
    if (ipClient == null) {
      return;
    }

    final Uint8List sendBuffer = packetRule.makeSendPacket(dataBuffer);

    ipClient.add(sendBuffer);
    return ipClient.flush();
  }

  Future<void> _onReceived(Uint8List receivedBuffer) async {
    await mutex.protect(() async {
      tempReceiveBuffer.add(receivedBuffer);
    });
  }

  void _onError(Object er) {
    ipClient.close();
    dispatchDisconnected(this);
  }
}
