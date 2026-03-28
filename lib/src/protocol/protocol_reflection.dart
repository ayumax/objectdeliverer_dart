import 'dart:typed_data';

import '../deliver_data.dart';
import '../utils/grow_buffer.dart';
import 'objectdeliverer_protocol.dart';

class ProtocolReflection extends ObjectDelivererProtocol {
  @override
  Future<void> start() async {
    dispatchConnected(this);
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> send(Uint8List dataBuffer) async {
    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    final tempBuffer = GrowBuffer()..add(sendBuffer);

    while (tempBuffer.length > 0) {
      final wantSize = packetRule.wantSize;

      if (wantSize > 0 && tempBuffer.length < wantSize) return;

      final receiveSize = wantSize == 0 ? tempBuffer.length : wantSize;
      final chunk = Uint8List.fromList(tempBuffer.takeBytes(0, receiveSize));

      for (final packet in packetRule.makeReceivedPacket(chunk)) {
        dispatchReceiveData(
            DeliverRawData.fromSenderAndBuffer(this, packet));
      }

      tempBuffer.removeRangeStart(receiveSize);
    }
  }
}
