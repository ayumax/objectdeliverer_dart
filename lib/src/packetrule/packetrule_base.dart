import 'dart:typed_data';

abstract class PacketRuleBase {
  int get wantSize;

  PacketRuleBase clonePacketRule();

  void initialize();

  Uint8List makeSendPacket(Uint8List bodyBuffer);

  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer);
}
