import 'dart:math';
import 'dart:typed_data';
import '../utils/grow_buffer.dart';
import 'packetrule_base.dart';

class PacketRuleFixedLength extends PacketRuleBase {
  PacketRuleFixedLength.fromParam(this.fixedSize);

  final GrowBuffer bufferForSend = GrowBuffer();

  int fixedSize = 128;

  @override
  int get wantSize => fixedSize;

  @override
  void initialize() {
    bufferForSend.setBufferSize(fixedSize);
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    bufferForSend.clear();

    final sendPacketSpan = Uint8List.fromList(
        bodyBuffer.take(min(bodyBuffer.length, fixedSize)).toList());

    bufferForSend.copyFrom(sendPacketSpan);

    return bufferForSend.memoryBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    if (wantSize > 0 && dataBuffer.length != wantSize) {
      return;
    }

    yield Uint8List.fromList(dataBuffer);
  }

  @override
  PacketRuleBase clonePacketRule() =>
      PacketRuleFixedLength.fromParam(fixedSize);
}
