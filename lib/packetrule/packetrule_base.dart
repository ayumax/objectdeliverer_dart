// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:typed_data';

abstract class PacketRuleBase {
  int get wantSize;

  PacketRuleBase clone();

  void initialize();

  Uint8List makeSendPacket(Uint8List bodyBuffer);

  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer);
}
