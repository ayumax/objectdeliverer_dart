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
    yield Uint8List.fromList(dataBuffer);
  }

  @override
  PacketRuleBase clonePacketRule() => PacketRuleNodivision();
}
