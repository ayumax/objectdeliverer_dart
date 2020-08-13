// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import '../PacketRule/packetrule_base.dart';
import '../PacketRule/packetrule_nodivision.dart';
import '../connected_data.dart';
import '../deliver_data.dart';

abstract class ObjectDelivererProtocol {
  bool _disposedValue = false;

  PublishSubject<ConnectedData> connected = PublishSubject<ConnectedData>();
  PublishSubject<ConnectedData> disconnected = PublishSubject<ConnectedData>();
  PublishSubject<DeliverData> receiveData = PublishSubject<DeliverData>();

  PacketRuleBase packetRule = PacketRuleNodivision();

  Future<void> startAsync();

  Future<void> closeAsync();

  Future<void> sendAsync(Uint8List dataBuffer);

  void setPacketRule(PacketRuleBase packetRule) {
    this.packetRule = packetRule;
    packetRule.initialize();
  }

  Future<void> dispose() async {
    connected.close();
    disconnected.close();
    receiveData.close();

    if (!_disposedValue) {
      await closeAsync();

      _disposedValue = true;
    }
  }

  void dispatchConnected(ObjectDelivererProtocol delivererProtocol) {
    connected.add(ConnectedData.fromTarget(delivererProtocol));
  }

  void dispatchDisconnected(ObjectDelivererProtocol delivererProtocol) {
    disconnected.add(ConnectedData.fromTarget(delivererProtocol));
  }

  void dispatchReceiveData(DeliverData deliverData) {
    receiveData.add(deliverData);
  }
}
