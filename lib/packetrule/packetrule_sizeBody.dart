// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
import 'dart:typed_data';

import 'packetRuleBase.dart';
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
  final GrowBuffer bufferForSend = GrowBuffer();
  EReceiveMode receiveMode = EReceiveMode.Size;
  int bodySize = 0;

  int sizeLength = 4;

  ECNBufferEndian sizeBufferEndian = ECNBufferEndian.Big;

  PacketRuleSizeBody.fromParam(this.sizeLength, this.sizeBufferEndian);

  @override
  int get wantSize {
    if (this.receiveMode == EReceiveMode.Size) {
      return this.sizeLength;
    }

    return this.bodySize;
  }

  @override
  void initialize() {
    this.bufferForSend.setBufferSize(1024);
    this.receiveMode = EReceiveMode.Size;
    this.bodySize = 0;
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    var bodyBufferNum = bodyBuffer.length;
    var sendSize = bodyBufferNum + this.sizeLength;

    this.bufferForSend.setBufferSize(sendSize);

    for (int i = 0; i < this.sizeLength; ++i) {
      int offset = 0;
      if (this.sizeBufferEndian == ECNBufferEndian.Big) {
        offset = 8 * (this.sizeLength - i - 1);
      } else {
        offset = 8 * i;
      }

      this.bufferForSend.memoryBuffer[i] = ((bodyBufferNum >> offset) & 0xFF);
    }

    this.bufferForSend.copyFrom(bodyBuffer, this.sizeLength);

    return this.bufferForSend.memoryBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    if (this.wantSize > 0 && dataBuffer.length != this.wantSize) return;

    if (this.receiveMode == EReceiveMode.Size) {
      this.onReceivedSize(dataBuffer);
      return;
    }

    this.onReceivedBody(dataBuffer);

    yield dataBuffer;
  }

  void onReceivedSize(Uint8List dataBuffer) {
    this.bodySize = 0;
    for (int i = 0; i < this.sizeLength; ++i) {
      int offset = 0;
      if (this.sizeBufferEndian == ECNBufferEndian.Big) {
        offset = 8 * (this.sizeLength - i - 1);
      } else {
        offset = 8 * i;
      }

      this.bodySize |= (dataBuffer[i] << offset);
    }

    this.receiveMode = EReceiveMode.Body;
  }

  void onReceivedBody(Uint8List dataBuffer) {
    this.bodySize = 0;

    this.receiveMode = EReceiveMode.Size;
  }

  @override
  PacketRuleBase clone() =>
      PacketRuleSizeBody.fromParam(this.sizeLength, this.sizeBufferEndian);
}
