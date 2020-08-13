// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.
import 'dart:typed_data';

import 'packetrule_base.dart';
import '../Utils/growBuffer.dart';

enum ECNBufferEndian {
  // Big Endian
  Big,
  // Little Endian
  Little,
}

enum EReceiveMode {
  Size,
  Body,
}

class PacketRuleSizeBody extends PacketRuleBase {
  PacketRuleSizeBody.fromParam(this.sizeLength, this.sizeBufferEndian);

  final GrowBuffer bufferForSend = GrowBuffer();
  EReceiveMode receiveMode = EReceiveMode.Size;
  int bodySize = 0;

  int sizeLength = 4;

  ECNBufferEndian sizeBufferEndian = ECNBufferEndian.Big;

  @override
  int get wantSize {
    if (receiveMode == EReceiveMode.Size) {
      return sizeLength;
    }

    return bodySize;
  }

  @override
  void initialize() {
    bufferForSend.setBufferSize(1024);
    receiveMode = EReceiveMode.Size;
    bodySize = 0;
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    final int bodyBufferNum = bodyBuffer.length;
    final int sendSize = bodyBufferNum + sizeLength;

    bufferForSend.setBufferSize(sendSize);

    for (int i = 0; i < sizeLength; ++i) {
      int offset = 0;
      if (sizeBufferEndian == ECNBufferEndian.Big) {
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

    if (receiveMode == EReceiveMode.Size) {
      onReceivedSize(dataBuffer);
      return;
    }

    onReceivedBody(dataBuffer);

    yield Uint8List.fromList(dataBuffer);
  }

  void onReceivedSize(Uint8List dataBuffer) {
    bodySize = 0;
    for (int i = 0; i < sizeLength; ++i) {
      int offset = 0;
      if (sizeBufferEndian == ECNBufferEndian.Big) {
        offset = 8 * (sizeLength - i - 1);
      } else {
        offset = 8 * i;
      }

      bodySize |= dataBuffer[i] << offset;
    }

    receiveMode = EReceiveMode.Body;
  }

  void onReceivedBody(Uint8List dataBuffer) {
    bodySize = 0;

    receiveMode = EReceiveMode.Size;
  }

  @override
  PacketRuleBase clone() =>
      PacketRuleSizeBody.fromParam(sizeLength, sizeBufferEndian);
}
