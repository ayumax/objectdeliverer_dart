import 'dart:async';
import 'dart:typed_data';
import 'connected_data.dart';
import 'deliver_data.dart';
import 'deliverybox/deliverybox_base.dart';
import 'packetrule/packetrule_base.dart';
import 'protocol/objectdeliverer_protocol.dart';

class ObjectDelivererManager<T> {
  ObjectDelivererManager();

  ObjectDelivererProtocol? _currentProtocol;
  DeliveryBoxBase<T>? _deliveryBox;
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

  Future<void> start(
    ObjectDelivererProtocol protocol,
    PacketRuleBase packetRule, [
    DeliveryBoxBase<T>? deliveryBox,
  ]) async {
    if (_disposedValue) {
      return;
    }

    _currentProtocol = protocol..setPacketRule(packetRule);

    _deliveryBox = deliveryBox;

    _currentProtocol!.connected.listen((ConnectedData x) {
      _connectedList.add(x.target);
      _connected.sink.add(x);
    });

    _currentProtocol!.disconnected.listen((ConnectedData x) {
      _connectedList.remove(x.target);
      _disconnected.sink.add(x);
    });

    _currentProtocol!.receiveData.listen((DeliverRawData x) {
      final data = DeliverData<T>.fromSenderAndBuffer(x.sender, x.buffer);

      if (deliveryBox != null) {
        data.message = deliveryBox.bufferToMessage(x.buffer);
      }

      _receiveData.sink.add(data);
    });

    _connectedList.clear();

    return _currentProtocol!.start();
  }

  Future<void> send(Uint8List dataBuffer) async {
    final currentProtocol = _currentProtocol;
    if (currentProtocol == null || _disposedValue) {
      return;
    }

    return currentProtocol.send(dataBuffer);
  }

  Future<void> sendTo(
    Uint8List dataBuffer,
    ObjectDelivererProtocol target,
  ) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    return target.send(dataBuffer);
  }

  Future<void> sendMessage(T message) async {
    final deliveryBox = _deliveryBox;
    if (_disposedValue || deliveryBox == null) {
      return;
    }

    return send(deliveryBox.makeSendBuffer(message));
  }

  Future<void> sendToMessage(
    T message,
    ObjectDelivererProtocol target,
  ) async {
    final deliveryBox = _deliveryBox;
    if (_disposedValue || deliveryBox == null) {
      return;
    }

    return sendTo(deliveryBox.makeSendBuffer(message), target);
  }

  Future<void> close() async {
    if (!_disposedValue) {
      _disposedValue = true;

      await _connected.close();
      await _disconnected.close();
      await _receiveData.close();

      final currentProtocol = _currentProtocol;
      if (currentProtocol == null) {
        return;
      }

      await currentProtocol.close();

      await currentProtocol.dispose();

      _currentProtocol = null;
    }
  }
}
