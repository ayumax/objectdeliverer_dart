import 'dart:typed_data';
import 'protocol/objectdeliverer_protocol.dart';

class DeliverRawData {
  DeliverRawData.fromSenderAndBuffer(this.sender, this.buffer);

  ObjectDelivererProtocol sender;

  Uint8List buffer;
}

class DeliverData<T> extends DeliverRawData {
  DeliverData.fromSenderAndBuffer(
      ObjectDelivererProtocol sender, Uint8List buffer)
      : super.fromSenderAndBuffer(sender, buffer);

  T message;
}
