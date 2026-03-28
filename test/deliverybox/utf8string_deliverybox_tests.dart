import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Utf8StringDeliveryBox', () {
    test('Conversion check of Delivery Box', () async {
      const checkString = 'ABCDEFG_012345_@!#\r\nZXCVBefesdfr';

      final deliveryBox = Utf8StringDeliveryBox();

      final buffer = deliveryBox.makeSendBuffer(checkString);

      await expectLater(deliveryBox.bufferToMessage(buffer), checkString);
    });

    test('Round-trip of multiple strings including CJK characters', () async {
      final deliveryBox = Utf8StringDeliveryBox();

      final testStrings = [
        'Hello World',
        'こんにちは世界',
        '你好世界',
        '¡Hola Mundo!',
        '1234567890!@#\$%^&*()_+',
      ];

      final buffers = <Uint8List>[];
      for (final str in testStrings) {
        buffers.add(deliveryBox.makeSendBuffer(str));
      }

      for (var i = 0; i < testStrings.length; i++) {
        await expectLater(
            deliveryBox.bufferToMessage(buffers[i]), testStrings[i]);
      }
    });
  });
}
