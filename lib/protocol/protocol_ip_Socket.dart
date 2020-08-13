// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:async';
import 'dart:typed_data';

import 'package:mutex/mutex.dart';

import '../Utils/growBuffer.dart';
import '../Utils/polling_task.dart';
import '../deliver_data.dart';
import 'objectdeliverer_protocol.dart';

abstract class ProtocolIpSocket extends ObjectDelivererProtocol {
  void startReceive() {
    _receiveTask = PollingTask.fromAction(receivedDatas);
  }

  Future<void> stopReceive() async {
    await _receiveTask.stopAsync();

    _receiveTask = null;
  }

  PollingTask _receiveTask;

  GrowBuffer tempReceiveBuffer = GrowBuffer();

  Mutex mutex;

  Future<bool> receivedDatas() async {
    while (tempReceiveBuffer.length > 0) {
      await mutex.protect(() async {
        final int wantSize = packetRule.wantSize;

        if (wantSize > 0) {
          if (tempReceiveBuffer.length < wantSize) {
            return true;
          }
        }

        final int receiveSize =
            wantSize == 0 ? tempReceiveBuffer.length : wantSize;
        final Uint8List spanTempReceiveBuffer =
            tempReceiveBuffer.takeBytes(0, receiveSize);

        for (final Uint8List receivedMemory
            in packetRule.makeReceivedPacket(spanTempReceiveBuffer)) {
          dispatchReceiveData(
              DeliverRawData.fromSenderAndBuffer(this, receivedMemory));
        }

        tempReceiveBuffer.removeRangeStart(receiveSize);
      });
    }

    return true;
  }
}
