import 'dart:typed_data';

import '../utils/grow_buffer.dart';

import 'packetrule_base.dart';

enum ECNBufferEndian {
  // Big Endian
  big,
  // Little Endian
  little,
}

enum EReceiveMode {
  size,
  body,
}

class PacketRuleSizeBody extends PacketRuleBase {
  PacketRuleSizeBody.fromParam(this.sizeLength,
      {this.sizeBufferEndian = ECNBufferEndian.big});

  final GrowBuffer bufferForSend = GrowBuffer();
  EReceiveMode receiveMode = EReceiveMode.size;
  int bodySize = 0;

  int sizeLength = 4;

  ECNBufferEndian sizeBufferEndian = ECNBufferEndian.big;

  @override
  int get wantSize {
    if (receiveMode == EReceiveMode.size) {
      return sizeLength;
    }

    return bodySize;
  }

  @override
  void initialize() {
    bufferForSend.setBufferSize(1024);
    receiveMode = EReceiveMode.size;
    bodySize = 0;
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    final bodyBufferNum = bodyBuffer.length;
    final sendSize = bodyBufferNum + sizeLength;

    bufferForSend.setBufferSize(sendSize);

    for (var i = 0; i < sizeLength; ++i) {
      var offset = 0;
      if (sizeBufferEndian == ECNBufferEndian.big) {
        offset = 8 * (sizeLength - i - 1);
      } else {
        offset = 8 * i;
      }

      bufferForSend.memoryBuffer[i] = (bodyBufferNum >> offset) & 0xFF;
    }

    bufferForSend.copyFrom(bodyBuffer, sizeLength);

    return bufferForSend.memoryBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    if (wantSize > 0 && dataBuffer.length != wantSize) {
      return;
    }

    if (receiveMode == EReceiveMode.size) {
      onReceivedSize(dataBuffer);
      return;
    }

    onReceivedBody(dataBuffer);

    yield Uint8List.fromList(dataBuffer);
  }

  void onReceivedSize(Uint8List dataBuffer) {
    bodySize = 0;
    for (var i = 0; i < sizeLength; ++i) {
      var offset = 0;
      if (sizeBufferEndian == ECNBufferEndian.big) {
        offset = 8 * (sizeLength - i - 1);
      } else {
        offset = 8 * i;
      }

      bodySize |= dataBuffer[i] << offset;
    }

    receiveMode = EReceiveMode.body;
  }

  void onReceivedBody(Uint8List dataBuffer) {
    bodySize = 0;

    receiveMode = EReceiveMode.size;
  }

  @override
  PacketRuleBase clonePacketRule() => PacketRuleSizeBody.fromParam(sizeLength,
      sizeBufferEndian: sizeBufferEndian);
}
