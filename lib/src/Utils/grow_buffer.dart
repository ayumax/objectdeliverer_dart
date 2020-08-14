import 'dart:math';
import 'dart:typed_data';

class GrowBuffer {
  GrowBuffer({int initialSize = 1024, int packetSize = 1024}) {
    _packetSize = packetSize;
    setBufferSize(initialSize);
  }

  int _packetSize;
  Uint8List _innerBuffer = Uint8List(0);

  int _length = 0;
  int get length => _length;

  Uint8List get memoryBuffer => takeBytes(0, _length);

  int get innerBufferSize => _innerBuffer.length;

  Uint8List takeBytes(int position, int takeLength) =>
      Uint8List.view(_innerBuffer.buffer, position, takeLength);

  Uint8List toBytes(int position, int takeLength) =>
      Uint8List.fromList(takeBytes(position, takeLength));

  Uint8List toAllBytes() => toBytes(0, length);

  bool setBufferSize([int newSize = 0]) {
    var isGrow = false;

    if (_innerBuffer.length < newSize) {
      final oldBuffer = _innerBuffer;
      _innerBuffer = Uint8List(_packetSize * ((newSize ~/ _packetSize) + 1))
        ..setRange(0, oldBuffer.length, oldBuffer);

      isGrow = true;
    }

    _length = newSize;

    return isGrow;
  }

  void add(Uint8List addBuffer) {
    setBufferSize(length + addBuffer.length);

    final startOffset = length - addBuffer.length;
    _innerBuffer.setRange(
        startOffset, startOffset + addBuffer.length, addBuffer);
  }

  void copyFrom(Uint8List fromBuffer, [int myOffset = 0]) {
    _innerBuffer.setRange(
        myOffset,
        myOffset + min(fromBuffer.length, length - myOffset).toInt(),
        fromBuffer);
  }

  void removeRangeStart(int length) {
    final moveLength = this.length - length;

    final oldBuffer = _innerBuffer;
    _innerBuffer = Uint8List(innerBufferSize)
      ..setRange(0, moveLength, oldBuffer, length);

    _length = moveLength;
  }

  void clear() {
    _innerBuffer.fillRange(0, _innerBuffer.length, 0);
  }
}
