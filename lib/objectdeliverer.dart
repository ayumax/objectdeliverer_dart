library objectdeliverer_dart;

import 'dart:async';
import 'dart:core';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import 'PacketRule/packetrule_base.dart';
import 'connected_data.dart';
import 'deliver_data.dart';
import 'deliveryBox/deliverybox_base.dart';
import 'protocol/objectdeliverer_protocol.dart';

class ObjectDelivererManager<T> {
  ObjectDelivererManager();

  ObjectDelivererProtocol _currentProtocol;
  DeliveryBoxBase<T> _deliveryBox;
  bool _disposedValue = false;

  PublishSubject<ConnectedData> connected = PublishSubject<ConnectedData>();
  PublishSubject<ConnectedData> disconnected = PublishSubject<ConnectedData>();
  PublishSubject<DeliverData<T>> receiveData = PublishSubject<DeliverData<T>>();

  bool get isConnected => connectedList.isNotEmpty;

  final List<ObjectDelivererProtocol> _connectedList =
      <ObjectDelivererProtocol>[];
  List<ObjectDelivererProtocol> get connectedList => _connectedList;

  Future<void> startAsync(
      ObjectDelivererProtocol protocol, PacketRuleBase packetRule,
      [DeliveryBoxBase<T> deliveryBox]) async {
    if (protocol == null || packetRule == null) {
      return;
    }

    _currentProtocol = protocol..setPacketRule(packetRule);

    _deliveryBox = deliveryBox;

    _currentProtocol.connected.listen((ConnectedData x) {
      _connectedList.add(x.target);
      connected.add(x);
    });

    _currentProtocol.disconnected.listen((ConnectedData x) {
      _connectedList.remove(x.target);
      disconnected.add(x);
    });

    _currentProtocol.receiveData.listen((DeliverRawData x) {
      final DeliverData<T> data =
          DeliverData<T>.fromSenderAndBuffer(x.sender, x.buffer);

      if (deliveryBox != null) {
        data.message = deliveryBox.bufferToMessage(x.buffer);
      }

      receiveData.add(data);
    });

    _connectedList.clear();

    return _currentProtocol.startAsync();
  }

  Future<void> sendAsync(Uint8List dataBuffer) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    return _currentProtocol.sendAsync(dataBuffer);
  }

  Future<void> sendToAsync(
      Uint8List dataBuffer, ObjectDelivererProtocol target) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    if (target != null) {
      return target.sendAsync(dataBuffer);
    }
  }

  Future<void> sendMessageAsync(T message) async {
    if (_deliveryBox == null) {
      return;
    }

    return sendAsync(_deliveryBox.makeSendBuffer(message));
  }

  Future<void> sendToMessageAsync(
      T message, ObjectDelivererProtocol target) async {
    if (_deliveryBox == null) {
      return;
    }

    return sendToAsync(_deliveryBox.makeSendBuffer(message), target);
  }

  Future<void> close() async {
    if (!_disposedValue) {
      _disposedValue = true;

      if (_currentProtocol == null) {
        return;
      }

      await _currentProtocol.closeAsync();

      _currentProtocol.dispose();

      _currentProtocol = null;
    }
  }
}
