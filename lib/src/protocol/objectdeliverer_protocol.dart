import 'dart:async';
import 'dart:typed_data';

import '../connected_data.dart';
import '../deliver_data.dart';
import '../packetrule/packetrule_base.dart';
import '../packetrule/packetrule_nodivision.dart';

abstract class ObjectDelivererProtocol {
  bool _disposedValue = false;

  final _connected = StreamController<ConnectedData>.broadcast();
  final _disconnected = StreamController<ConnectedData>.broadcast();
  final _receiveData = StreamController<DeliverRawData>.broadcast();

  Stream<ConnectedData> get connected => _connected.stream;
  Stream<ConnectedData> get disconnected => _disconnected.stream;
  Stream<DeliverRawData> get receiveData => _receiveData.stream;

  PacketRuleBase packetRule = PacketRuleNodivision();

  Future start();

  Future close();

  Future send(Uint8List dataBuffer);

  void setPacketRule(PacketRuleBase packetRule) {
    this.packetRule = packetRule;
    packetRule.initialize();
  }

  Future dispose() async {
    if (!_disposedValue) {
      await _connected.close();
      await _disconnected.close();
      await _receiveData.close();

      await close();

      _disposedValue = true;
    }
  }

  void dispatchConnected(ObjectDelivererProtocol delivererProtocol) {
    if (_disposedValue == false) {
      _connected.sink.add(ConnectedData.fromTarget(delivererProtocol));
    }
  }

  void dispatchDisconnected(ObjectDelivererProtocol delivererProtocol) {
    if (_disposedValue == false) {
      _disconnected.sink.add(ConnectedData.fromTarget(delivererProtocol));
    }
  }

  void dispatchReceiveData(DeliverRawData deliverData) {
    if (_disposedValue == false) {
      _receiveData.sink.add(deliverData);
    }
  }
}
