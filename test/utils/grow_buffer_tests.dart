import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GrowBuffer', () {
    test('common', () async {
      const packetSize = 1024;

      final buffer = GrowBuffer(initialSize: 100);

      await expectLater(buffer.length, 100);
      await expectLater(buffer.innerBufferSize, packetSize);

      buffer.setBufferSize(2000);

      await expectLater(buffer.length, 2000);
      await expectLater(buffer.innerBufferSize, packetSize * 2);

      buffer.add(Uint8List.fromList([1, 2, 3]));

      await expectLater(buffer.length, 2003);
      await expectLater(buffer.innerBufferSize, packetSize * 2);
      await expectLater(buffer.memoryBuffer[2000], 1);
      await expectLater(buffer.memoryBuffer[2001], 2);
      await expectLater(buffer.memoryBuffer[2002], 3);

      buffer.removeRangeStart(2000);
      await expectLater(buffer.length, 3);
      await expectLater(buffer.innerBufferSize, packetSize * 2);
      await expectLater(buffer.memoryBuffer[0], 1);
      await expectLater(buffer.memoryBuffer[1], 2);
      await expectLater(buffer.memoryBuffer[2], 3);

      buffer.copyFrom(Uint8List.fromList([0xEE, 0xFF]), 1);
      await expectLater(buffer.length, 3);
      await expectLater(buffer.innerBufferSize, packetSize * 2);
      await expectLater(buffer.memoryBuffer[0], 1);
      await expectLater(buffer.memoryBuffer[1], 0xEE);
      await expectLater(buffer.memoryBuffer[2], 0xFF);
    });
  });
}
