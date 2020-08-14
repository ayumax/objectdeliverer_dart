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
  PublishSubject<DeliverRawData> receiveData = PublishSubject<DeliverRawData>();

  PacketRuleBase packetRule = PacketRuleNodivision();

  Future<void> startAsync();

  Future<void> closeAsync();

  Future<void> sendAsync(Uint8List dataBuffer);

  void setPacketRule(PacketRuleBase packetRule) {
    this.packetRule = packetRule;
    packetRule.initialize();
  }

  Future<void> dispose() async {
    await connected.close();
    await disconnected.close();
    await receiveData.close();

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

  void dispatchReceiveData(DeliverRawData deliverData) {
    receiveData.add(deliverData);
  }
}
