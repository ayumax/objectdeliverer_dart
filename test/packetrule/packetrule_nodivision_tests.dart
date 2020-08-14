import 'dart:typed_data';

import 'package:objectdeliverer_dart/src/packetrule/packetrule_nodivision.dart';
import 'package:test/test.dart';

void main() {
  group('PacketRuleNodivision MakeSendPacketTest', () {
    test('1', () async {
      final packetRule = PacketRuleNodivision()..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(actual, expected);
    });
  });

  group('PacketRuleNodivision MakeReceivedPacket', () {
    test('1', () async {
      final packetRule = PacketRuleNodivision()..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 1);
      await expectLater(actual.first, expected);
    });
  });
}
