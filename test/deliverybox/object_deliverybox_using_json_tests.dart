import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

class TestObject extends IJsonSerializable {
  TestObject() {
    IJsonSerializable.addMakeInstanceFunction(TestObject, (json) {
      final testObj = TestObject()
        ..intProperty = json['intProperty'] as int
        ..stringProperty = json['stringProperty'] as String
        ..doubleProperty = json['doubleProperty'] as double;

      return testObj;
    });
  }

  int intProperty;
  String stringProperty;
  double doubleProperty;

  @override
  Map<String, dynamic> toJson() => {
        'intProperty': intProperty,
        'stringProperty': stringProperty,
        'doubleProperty': doubleProperty
      };
}

void main() {
  group('ObjectDeliveryBoxUsingJson', () {
    test('Conversion check of Delivery Box', () async {
      final deliveryBox = ObjectJsonDeliveryBox<TestObject>();

      final testObj = TestObject()
        ..intProperty = 10
        ..stringProperty = 'abcdEFG'
        ..doubleProperty = 3.14;

      final buffer = deliveryBox.makeSendBuffer(testObj);
      final deserializedObj = deliveryBox.bufferToMessage(buffer);

      await expectLater(deserializedObj.intProperty, 10);
      await expectLater(deserializedObj.stringProperty, 'abcdEFG');
      await expectLater(deserializedObj.doubleProperty, 3.14);
    });
  });
}
