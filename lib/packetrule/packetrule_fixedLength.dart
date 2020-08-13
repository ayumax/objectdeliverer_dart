// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.
import 'dart:math';
import 'dart:typed_data';
import '../Utils/growBuffer.dart';
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

    final Uint8List sendPacketSpan = Uint8List.fromList(
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
  PacketRuleBase clone() => PacketRuleFixedLength.fromParam(fixedSize);
}
