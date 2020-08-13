// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:typed_data';

import '../Utils/growBuffer.dart';
import 'packetrule_base.dart';

class PacketRuleTerminate extends PacketRuleBase {
  PacketRuleTerminate.fromParam(this.terminate);

  final GrowBuffer _bufferForSend = GrowBuffer();
  final GrowBuffer _receiveTempBuffer = GrowBuffer();
  final GrowBuffer _bufferForReceive = GrowBuffer();

  Uint8List terminate = Uint8List(0);

  @override
  int get wantSize => 0;

  @override
  void initialize() {
    _bufferForSend.setBufferSize(0);
    _receiveTempBuffer.setBufferSize(0);
    _bufferForReceive.setBufferSize(0);
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    _bufferForSend.add(terminate);

    return _bufferForSend.memoryBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    if (wantSize > 0 && dataBuffer.length != wantSize) {
      return;
    }

    _receiveTempBuffer.add(dataBuffer);

    int findIndex = -1;

    while (true) {
      for (int i = 0; i <= _receiveTempBuffer.length - terminate.length; ++i) {
        bool notEqual = false;
        for (int j = 0; j < terminate.length; ++j) {
          if (_receiveTempBuffer.memoryBuffer[i + j] != terminate[j]) {
            notEqual = true;
            break;
          }
        }

        if (notEqual == false) {
          findIndex = i;
          break;
        }
      }

      if (findIndex == -1) {
        return;
      }

      _bufferForReceive.setBufferSize(findIndex);
      _bufferForReceive.copyFrom(_receiveTempBuffer.takeBytes(0, findIndex));

      yield _bufferForReceive.toAllBytes();

      _receiveTempBuffer.removeRangeStart(findIndex + terminate.length);

      findIndex = -1;
    }
  }

  @override
  PacketRuleBase clone() => PacketRuleTerminate.fromParam(terminate);
}
