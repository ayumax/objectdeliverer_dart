// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

import 'dart:math';
import 'dart:typed_data';

class GrowBuffer {
  int _packetSize;
  Uint8List _innerBuffer = Uint8List();

  GrowBuffer({int initialSize = 1024, int packetSize = 1024}) {
    this._packetSize = packetSize;
    this.setBufferSize(initialSize);
  }

  int _length = 0;
  int get length => _length;

  Uint8List get memoryBuffer => this._innerBuffer;

  int get innerBufferSize => this._innerBuffer.length;

  Iterable<int> asSpan(int position, int takeLength) =>
      this._innerBuffer.skip(position).take(takeLength);

  bool setBufferSize([int newSize = 0]) {
    bool isGrow = false;

    if (this._innerBuffer.length < newSize) {
      var oldBuffer = this._innerBuffer;
      this._innerBuffer =
          Uint8List(this._packetSize * ((newSize ~/ this._packetSize) + 1));

      this._innerBuffer.setRange(0, oldBuffer.length, oldBuffer);

      isGrow = true;
    }

    this._length = newSize;

    return isGrow;
  }

  void add(Uint8List addBuffer) {
    this.setBufferSize(this.length + addBuffer.length);

    final int startOffset = this.length - addBuffer.length;
    this
        ._innerBuffer
        .setRange(startOffset, startOffset + addBuffer.length, addBuffer);
  }

  void copyFrom(Uint8List fromBuffer, [int myOffset = 0]) {
    this._innerBuffer.setRange(myOffset,
        myOffset + min(fromBuffer.length, this.length - myOffset), fromBuffer);
  }

  void removeRangeFromStart(int start, int length) {
    var moveLength = this.length - length;
    var tempBuffer = Uint8List(moveLength);

    tempBuffer.setRange(0, moveLength, this._innerBuffer, start + length);
    this._innerBuffer.setRange(start, moveLength, tempBuffer);

    this._length = moveLength;
  }

  void clear() {
    this._innerBuffer.fillRange(0, this._innerBuffer.length, 0);
  }
}
