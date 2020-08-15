import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

void main() {
  group('PacketRuleTerminate MakeSendPacketTest', () {
    test('terminate is {0xFE, 0xFF}', () async {
      final packetRule =
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xEF]))
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(
          actual.length, expected.length + packetRule.terminate.length);

      await expectLater(
          actual.take(actual.length - packetRule.terminate.length).toList(),
          expected);

      await expectLater(
          actual.skip(expected.length).toList(), packetRule.terminate);
    });
  });

  group('PacketRuleTerminate MakeReceivedPacket', () {
    test('terminate is {0xFE, 0xFF}. just size.', () async {
      final packetRule =
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xEF]))
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));

      final receiveBuffer = Uint8List.fromList(expected + packetRule.terminate);

      final actual = packetRule.makeReceivedPacket(receiveBuffer).toList();
      await expectLater(actual.length, 1);

      await expectLater(actual.first, expected);
    });

    test('terminate is {0xFE, 0xFF}. over size.', () async {
      final packetRule =
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xEF]))
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));

      final receiveBuffer = Uint8List.fromList(expected +
          packetRule.terminate +
          List.generate(10, (index) => 20 + index));

      final actual = packetRule.makeReceivedPacket(receiveBuffer).toList();
      await expectLater(actual.length, 1);

      await expectLater(actual.first, expected);
    });

    test('terminate is {0xFE, 0xFF}. over size.', () async {
      final packetRule =
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xEF]))
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final expected2 =
          Uint8List.fromList(List.generate(10, (index) => 20 + index));

      final receiveBuffer = Uint8List.fromList(
          expected + packetRule.terminate + expected2 + packetRule.terminate);

      final actual = packetRule.makeReceivedPacket(receiveBuffer).toList();

      var count = 0;
      for (final packet in actual) {
        switch (count++) {
          case 0:
            await expectLater(packet, expected);
            break;

          case 1:
            await expectLater(packet, expected2);
            break;
        }
      }

      await expectLater(count, 2);
    });
  });
}
