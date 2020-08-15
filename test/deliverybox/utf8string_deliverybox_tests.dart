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
  });
}
