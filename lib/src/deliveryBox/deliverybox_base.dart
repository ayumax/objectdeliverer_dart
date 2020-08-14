import 'dart:typed_data';

abstract class DeliveryBoxBase<T> {
  DeliveryBoxBase();

  Uint8List makeSendBuffer(T message);

  T bufferToMessage(Uint8List buffer);
}
