import 'dart:convert';
import 'dart:typed_data';
import 'deliverybox_base.dart';

abstract class IJsonSerializable {
  void fromJson(Map<String, dynamic> json);
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

    T message;

    // ignore: cascade_invocations
    message.fromJson(decordedJson);

    return message;
  }
}
