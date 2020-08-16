import 'dart:typed_data';
import 'protocol/objectdeliverer_protocol.dart';

/// Data reception event.
class DeliverRawData {
  DeliverRawData.fromSenderAndBuffer(this.sender, this.buffer);

  /// The sender who sent the data.
  ///
  /// If you save this value, you can use it later to specify the
  /// destination with [ObjectDelivererManager.sendTo] or
  ///  [ObjectDelivererManager.sendToMessage].
  ObjectDelivererProtocol sender;

  /// Received byte buffer.
  Uint8List buffer;
}

class DeliverData<T> extends DeliverRawData {
  DeliverData.fromSenderAndBuffer(
      ObjectDelivererProtocol sender, Uint8List buffer)
      : super.fromSenderAndBuffer(sender, buffer);

  /// Object that deserializes the received byte buffer.
  T message;
}
