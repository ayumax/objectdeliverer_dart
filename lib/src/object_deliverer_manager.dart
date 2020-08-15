import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'connected_data.dart';
import 'deliver_data.dart';
import 'deliverybox/deliverybox_base.dart';
import 'packetrule/packetrule_base.dart';
import 'protocol/objectdeliverer_protocol.dart';

class ObjectDelivererManager<T> {
  ObjectDelivererManager();

  ObjectDelivererProtocol _currentProtocol;
  DeliveryBoxBase<T> _deliveryBox;
  bool _disposedValue = false;

  final _connected = StreamController<ConnectedData>.broadcast();
  final _disconnected = StreamController<ConnectedData>.broadcast();
  final _receiveData = StreamController<DeliverData<T>>.broadcast();

  Stream<ConnectedData> get connected => _connected.stream;
  Stream<ConnectedData> get disconnected => _disconnected.stream;
  Stream<DeliverData<T>> get receiveData => _receiveData.stream;

  bool get isConnected => connectedList.isNotEmpty;

  final List<ObjectDelivererProtocol> _connectedList =
      <ObjectDelivererProtocol>[];
  List<ObjectDelivererProtocol> get connectedList => _connectedList;

  Future startAsync(ObjectDelivererProtocol protocol, PacketRuleBase packetRule,
      [DeliveryBoxBase<T> deliveryBox]) async {
    if (protocol == null || packetRule == null) {
      return;
    }

    _currentProtocol = protocol..setPacketRule(packetRule);

    _deliveryBox = deliveryBox;

    _currentProtocol.connected.listen((ConnectedData x) {
      _connectedList.add(x.target);
      _connected.sink.add(x);
    });

    _currentProtocol.disconnected.listen((ConnectedData x) {
      _connectedList.remove(x.target);
      _disconnected.sink.add(x);
    });

    _currentProtocol.receiveData.listen((DeliverRawData x) {
      final data = DeliverData<T>.fromSenderAndBuffer(x.sender, x.buffer);

      if (deliveryBox != null) {
        data.message = deliveryBox.bufferToMessage(x.buffer);
      }

      _receiveData.sink.add(data);
    });

    _connectedList.clear();

    return _currentProtocol.startAsync();
  }

  Future sendAsync(Uint8List dataBuffer) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    return _currentProtocol.sendAsync(dataBuffer);
  }

  Future sendToAsync(
      Uint8List dataBuffer, ObjectDelivererProtocol target) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    if (target != null) {
      return target.sendAsync(dataBuffer);
    }
  }

  Future sendMessageAsync(T message) async {
    if (_deliveryBox == null) {
      return;
    }

    return sendAsync(_deliveryBox.makeSendBuffer(message));
  }

  Future sendToMessageAsync(T message, ObjectDelivererProtocol target) async {
    if (_deliveryBox == null) {
      return;
    }

    return sendToAsync(_deliveryBox.makeSendBuffer(message), target);
  }

  Future close() async {
    if (!_disposedValue) {
      _disposedValue = true;

      await _connected.close();
      await _disconnected.close();
      await _receiveData.close();

      if (_currentProtocol == null) {
        return;
      }

      await _currentProtocol.closeAsync();

      await _currentProtocol.dispose();

      _currentProtocol = null;
    }
  }
}
