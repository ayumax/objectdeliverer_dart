import 'dart:typed_data';

abstract class DeliveryBoxBase<T> {
  DeliveryBoxBase();

  /// Function to convert [message] to byte buffer
  Uint8List makeSendBuffer(T message);

  /// Function to convert byte buffer to [message]
  T bufferToMessage(Uint8List buffer);
}
