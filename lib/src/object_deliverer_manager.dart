import 'dart:async';
import 'dart:core';
import 'dart:typed_data';
import 'connected_data.dart';
import 'deliver_data.dart';
import 'deliverybox/deliverybox_base.dart';
import 'packetrule/packetrule_base.dart';
import 'protocol/objectdeliverer_protocol.dart';

/// Communication management class.
///
/// Usage:
///
///     // Create an ObjectDelivererManager.
///     final deliverer = ObjectDelivererManager<String>();
///
///     // Watching for connection events
///     deliverer.connected.listen((x) async {
///      print('connected');
///
///     // Sending data to a connected party
///      await deliverer.send(Uint8List.fromList([0x00, 0x12]));
///      await deliverer.send(Uint8List.fromList([0x00, 0x12, 0x23]));
///     });
///
///     // Watching for disconnection events.
///     deliverer.disconnected.listen((x) => print('disconnected'));
///
///     // Watching for incoming events
///     deliverer.receiveData.listen((x) {
///       print('received buffer length = ${x.buffer.length}');
///       print('received message = ${x.message}');
///     });
///
///     // Start the ObjectDelivererManager
///     await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
///         PacketRuleFixedLength.fromParam(10), Utf8StringDeliveryBox());
///
///     await Future.delayed(const Duration(milliseconds: 100));
///
///     // Close ObjectDelivererManager
///     await deliverer.close();
///
class ObjectDelivererManager<T> {
  ObjectDelivererManager();

  ObjectDelivererProtocol _currentProtocol;
  DeliveryBoxBase<T> _deliveryBox;
  bool _disposedValue = false;

  final _connected = StreamController<ConnectedData>.broadcast();
  final _disconnected = StreamController<ConnectedData>.broadcast();
  final _receiveData = StreamController<DeliverData<T>>.broadcast();

  /// Connection start event.
  Stream<ConnectedData> get connected => _connected.stream;

  /// Disconnection event.
  Stream<ConnectedData> get disconnected => _disconnected.stream;

  /// Data reception event.
  Stream<DeliverData<T>> get receiveData => _receiveData.stream;

  /// A flag that indicates whether it is connected
  bool get isConnected => connectedList.isNotEmpty;

  final List<ObjectDelivererProtocol> _connectedList =
      <ObjectDelivererProtocol>[];
  List<ObjectDelivererProtocol> get connectedList => _connectedList;

  /// start communication protocol.
  ///
  /// [protocol] is Communication protocol.
  /// [packetRule] is Data division rule.
  /// [deliveryBox] is Serialization method(optional)
  Future start(ObjectDelivererProtocol protocol, PacketRuleBase packetRule,
      [DeliveryBoxBase<T> deliveryBox]) async {
    if (_disposedValue || protocol == null || packetRule == null) {
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

    return _currentProtocol.start();
  }

  /// send the data to the connection destination.
  ///
  /// [dataBuffer] is transmission data.
  Future send(Uint8List dataBuffer) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    return _currentProtocol.send(dataBuffer);
  }

  /// specify the destination and send the data to the connection destination.
  ///
  /// [dataBuffer] is transmission data.
  /// [target] is the destination.
  Future sendTo(Uint8List dataBuffer, ObjectDelivererProtocol target) async {
    if (_currentProtocol == null || _disposedValue) {
      return;
    }

    if (target != null) {
      return target.send(dataBuffer);
    }
  }

  /// Convert message to byte buffer and send (DeliveryBox must be used).
  Future sendMessage(T message) async {
    if (_disposedValue || _deliveryBox == null) {
      return;
    }

    return send(_deliveryBox.makeSendBuffer(message));
  }

  /// Specify destination and convert message to byte buffer and send (use of DeliveryBox is required).
  Future sendToMessage(T message, ObjectDelivererProtocol target) async {
    if (_disposedValue || _deliveryBox == null) {
      return;
    }

    return sendTo(_deliveryBox.makeSendBuffer(message), target);
  }

  /// close communication protocol.
  Future close() async {
    if (!_disposedValue) {
      _disposedValue = true;

      await _connected.close();
      await _disconnected.close();
      await _receiveData.close();

      if (_currentProtocol == null) {
        return;
      }

      await _currentProtocol.close();

      await _currentProtocol.dispose();

      _currentProtocol = null;
    }
  }
}
