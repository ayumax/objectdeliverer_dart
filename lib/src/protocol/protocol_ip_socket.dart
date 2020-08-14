import 'dart:async';
import 'dart:typed_data';

import 'package:mutex/mutex.dart';

import '../deliver_data.dart';
import '../utils/grow_buffer.dart';
import '../utils/polling_task.dart';
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
        final wantSize = packetRule.wantSize;

        if (wantSize > 0) {
          if (tempReceiveBuffer.length < wantSize) {
            return true;
          }
        }

        final receiveSize = wantSize == 0 ? tempReceiveBuffer.length : wantSize;
        final spanTempReceiveBuffer =
            tempReceiveBuffer.takeBytes(0, receiveSize);

        for (final receivedMemory
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
