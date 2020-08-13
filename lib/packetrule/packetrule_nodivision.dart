// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:typed_data';

import 'packetrule_base.dart';

class PacketRuleNodivision extends PacketRuleBase {
  @override
  int get wantSize => 0;

  @override
  void initialize() {}

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    return bodyBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    yield dataBuffer;
  }

  @override
  PacketRuleBase clone() => PacketRuleNodivision();
}
