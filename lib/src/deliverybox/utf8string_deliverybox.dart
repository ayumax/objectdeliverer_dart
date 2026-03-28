import 'dart:convert';
import 'dart:typed_data';

import 'deliverybox_base.dart';

class Utf8StringDeliveryBox extends DeliveryBoxBase<String> {
  @override
  Uint8List makeSendBuffer(String message) =>
      Uint8List.fromList(utf8.encode(message));
  @override
  String bufferToMessage(Uint8List buffer) => utf8.decode(buffer);
}
