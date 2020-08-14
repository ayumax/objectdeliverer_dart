import 'dart:typed_data';

import 'package:objectdeliverer_dart/src/packetrule/packetrule_fixedlength.dart';
import 'package:test/test.dart';

void main() {
  group('PacketRuleFixedLength MakeSendPacketTest', () {
    test('If the transmit buffer size and the fixed size are the same',
        () async {
      final packetRule = PacketRuleFixedLength.fromParam(10)..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(actual.length, packetRule.fixedSize);
      await expectLater(actual, expected);
    });

    test('When the transmit buffer size is less than the fixed size', () async {
      final packetRule = PacketRuleFixedLength.fromParam(20)..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(actual.length, packetRule.fixedSize);
      await expectLater(Uint8List.fromList(actual.take(10).toList()), expected);
      await expectLater(Uint8List.fromList(actual.skip(10).take(10).toList()),
          List.generate(10, (index) => 0));
    });
  });

  group('PacketRuleFixedLength MakeReceivedPacket', () {
    test('1', () async {
      final packetRule = PacketRuleFixedLength.fromParam(10)..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 1);
      await expectLater(actual.first.length, packetRule.fixedSize);
      await expectLater(actual.first, expected);
    });

    test('2', () async {
      final packetRule = PacketRuleFixedLength.fromParam(20)..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 0);
    });

    test('3', () async {
      final packetRule = PacketRuleFixedLength.fromParam(10)..initialize();

      final expected = Uint8List.fromList(List.generate(20, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 0);
    });
  });
}
