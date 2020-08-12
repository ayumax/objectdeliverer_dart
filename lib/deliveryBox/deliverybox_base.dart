// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

import 'dart:typed_data';

abstract class DeliveryBoxBase<T> {
  DeliveryBoxBase();

  Uint8List makeSendBuffer(T message);

  T bufferToMessage(Uint8List buffer);
}
