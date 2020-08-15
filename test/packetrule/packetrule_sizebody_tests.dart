import 'dart:typed_data';

import 'package:objectdeliverer_dart/src/packetrule/packetrule_sizebody.dart';
import 'package:test/test.dart';

void main() {
  group('PacketRuleSizeBody MakeSendPacketTest', () {
    test('size is big endian', () async {
      final packetRule =
          PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.big)
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(actual.length, expected.length + packetRule.sizeLength);
      final actualSize =
          actual[0] << 24 | actual[1] << 16 | actual[2] << 8 | actual[3];

      await expectLater(actualSize, expected.length);
      await expectLater(actual.skip(4), expected);
    });

    test('size is littel endian', () async {
      final packetRule =
          PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.little)
            ..initialize();

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeSendPacket(expected);

      await expectLater(actual.length, expected.length + packetRule.sizeLength);
      final actualSize =
          actual[3] << 24 | actual[2] << 16 | actual[1] << 8 | actual[0];

      await expectLater(actualSize, expected.length);
      await expectLater(actual.skip(4), expected);
    });
  });

  group('PacketRuleSizeBody MakeReceivedPacket', () {
    test('size is big endian', () async {
      final packetRule =
          PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.big)
            ..initialize();

      await expectLater(packetRule.wantSize, packetRule.sizeLength);

      final expectedSizeBuffer = Uint8List.fromList([0, 0, 0, 10]);

      final actual0 = packetRule.makeReceivedPacket(expectedSizeBuffer);

      await expectLater(actual0.length, 0);
      await expectLater(packetRule.wantSize, 10);

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 1);
      await expectLater(actual.first, expected);
    });

    test('size is littele endian', () async {
      final packetRule =
          PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.little)
            ..initialize();

      await expectLater(packetRule.wantSize, packetRule.sizeLength);

      final expectedSizeBuffer = Uint8List.fromList([10, 0, 0, 0]);

      final actual0 = packetRule.makeReceivedPacket(expectedSizeBuffer);

      await expectLater(actual0.length, 0);
      await expectLater(packetRule.wantSize, 10);

      final expected = Uint8List.fromList(List.generate(10, (index) => index));
      final actual = packetRule.makeReceivedPacket(expected).toList();

      await expectLater(actual.length, 1);
      await expectLater(actual.first, expected);
    });
  });
}
