// Copyright (c) 2020 ayuma_x. All rights reserved.
// Licensed under the BSD license. See LICENSE file in the project root for full license information.

import 'dart:io';
import 'dart:typed_data';

import 'package:objectdeliverer_dart/connected_data.dart';
import 'package:objectdeliverer_dart/deliver_data.dart';

import '../Utils/polling_task.dart';

import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpServer extends ObjectDelivererProtocol {
  final List<ProtocolTcpIpSocket> _connectedSockets =
      List<ProtocolTcpIpSocket>(0);

  ServerSocket _tcpListener;
  PollingTask _waitClientsTask;

  int listenPort;

  @override
  Future<void> startAsync() async {
    _tcpListener = await ServerSocket.bind(InternetAddress.anyIPv4, listenPort);
    _tcpListener.listen((Socket connectedClientSocket) {
      final ProtocolTcpIpSocket clientSocket =
          ProtocolTcpIpSocket.fromConnectedSocket(connectedClientSocket)
            ..disconnected.listen(
                (ConnectedData x) => _clientSocketDisconnected(x.target))
            ..receiveData.listen((DeliverRawData x) => dispatchReceiveData(x))
            ..setPacketRule(packetRule.clone());

      _connectedSockets.add(clientSocket);

      dispatchConnected(clientSocket);
    });
  }

  @override
  Future<void> closeAsync() async {
    _tcpListener.close();
    _tcpListener = null;

    final List<Future<void>> closeTasks = List<Future<void>>(0);

    if (_waitClientsTask != null) {
      closeTasks.add(_waitClientsTask.stopAsync());
    }

    for (final ProtocolTcpIpSocket clientSocket in _connectedSockets) {
      await clientSocket.closeAsync();
      closeTasks.add(clientSocket.closeAsync());
    }

    _connectedSockets.clear();

    return Future.wait(closeTasks);
  }

  @override
  Future<void> sendAsync(Uint8List dataBuffer) {
    final List<Future<void>> sendTasks = List<Future<void>>(0);

    for (final ProtocolTcpIpSocket clientSocket in _connectedSockets) {
      sendTasks.add(clientSocket.sendAsync(dataBuffer));
    }

    return Future.wait(sendTasks);
  }

  Future<void> _clientSocketDisconnected(
      ObjectDelivererProtocol delivererProtocol) async {
    if (delivererProtocol == null) {
      return;
    }

    if (delivererProtocol is ProtocolTcpIpSocket == false) {
      return;
    }

    final ProtocolTcpIpSocket protocolTcpIp =
        delivererProtocol as ProtocolTcpIpSocket;
    final int foundIndex = _connectedSockets.indexOf(protocolTcpIp);

    if (foundIndex >= 0) {
      await protocolTcpIp.closeAsync();

      _connectedSockets.removeAt(foundIndex);

      dispatchDisconnected(protocolTcpIp);
    }
  }
}
