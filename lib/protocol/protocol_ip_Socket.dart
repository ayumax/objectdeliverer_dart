// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';

import '../Utils/growBuffer.dart';

import 'objectdeliverer_protocol.dart';

class ProtocolIPSocket extends ObjectDelivererProtocol {
  CancelableOperation<void> _receiveTask;

  GrowBuffer receiveBuffer = GrowBuffer();

  Socket ipClient;

  bool isSelfClose = false;

  @override
  Future<void> startAsync() async {}

  @override
  Future<void> closeAsync() async {
    if (ipClient == null) {
      return;
    }

    isSelfClose = true;

    await ipClient.close();

    _receiveTask.cancel();

    ipClient = null;
    _receiveTask = null;
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

  void startPollingForReceive(Socket connectionSocket) {
    ipClient = connectionSocket;

    _receiveTask = CancelableOperation<void>.fromFuture(receivedDatas(), onCancel: () => ,);
  }

  Future<void> receivedDatas() async => () {};
}
