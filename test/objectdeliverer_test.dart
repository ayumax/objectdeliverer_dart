import 'package:objectdeliverer_dart/src/deliveryBox/object_json_deliverybox.dart';
import 'package:test/test.dart';

class TestObj extends IJsonSerializable {
  int prop;

  @override
  void fromJson(Map<String, dynamic> json) {
    prop = json['prop'] as int;
  }

  @override
  Map<String, dynamic> toJson() => {'prop': prop};
}

void main() {
  group('DeliveryBox', () {
    test('Conversion check of Delivery Box', () async {
      final message = TestObj()..prop = 10;

      final box = ObjectJsonDeliveryBox<TestObj>();
      final buffer = box.makeSendBuffer(message);

      final box2 = box.bufferToMessage(buffer);

      await expectLater(box2.prop, 10);
    });
  });
}
