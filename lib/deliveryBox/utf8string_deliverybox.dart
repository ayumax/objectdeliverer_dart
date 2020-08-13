// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.
import 'dart:convert';
import 'dart:typed_data';

import 'deliverybox_base.dart';

class Utf8StringDeliveryBox extends DeliveryBoxBase<String> {
  @override
  Uint8List makeSendBuffer(String message) => utf8.encode(message) as Uint8List;
  @override
  String bufferToMessage(Uint8List buffer) => utf8.decode(buffer);
}
