import 'dart:convert';
import 'dart:typed_data';
import 'deliverybox_base.dart';

abstract class IJsonSerializable {
  static final Map<Type, IJsonSerializable Function(Map<String, dynamic>)>
      _makeInstanceFuncMap =
      <Type, IJsonSerializable Function(Map<String, dynamic>)>{};

  static void addMakeInstanceFunction(Type type,
      IJsonSerializable Function(Map<String, dynamic>) makeInstanceFunction) {
    _makeInstanceFuncMap[type] = makeInstanceFunction;
  }

  static IJsonSerializable makeInstance(Type type, Map<String, dynamic> json) {
    if (_makeInstanceFuncMap.containsKey(type) == false) {
      return null;
    }

    return _makeInstanceFuncMap[type](json);
  }

  Map<String, dynamic> toJson();
}

class ObjectJsonDeliveryBox<T extends IJsonSerializable>
    extends DeliveryBoxBase<T> {
  @override
  Uint8List makeSendBuffer(T message) =>
      utf8.encode(jsonEncode(message)) as Uint8List;

  @override
  T bufferToMessage(Uint8List buffer) {
    if (buffer.isEmpty) {
      return null;
    }

    if (buffer[buffer.length - 1] == 0x00) {
      // Remove the terminal null
      buffer.removeLast();
    }

    final decordedJson =
        jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>;

    return IJsonSerializable.makeInstance(T, decordedJson) as T;
  }
}
