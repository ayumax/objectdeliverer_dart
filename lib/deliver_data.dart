// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

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
