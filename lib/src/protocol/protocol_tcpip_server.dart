import 'dart:io';
import 'dart:typed_data';

import '../connected_data.dart';
import '../utils/polling_task.dart';
import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpServer extends ObjectDelivererProtocol {
  ProtocolTcpIpServer.fromParam(this.listenPort);

  final List<ProtocolTcpIpSocket> _connectedSockets =
      List<ProtocolTcpIpSocket>(0);

  ServerSocket _tcpListener;
  PollingTask _waitClientsTask;

  int listenPort;

  @override
  Future<void> startAsync() async {
    _tcpListener = await ServerSocket.bind(InternetAddress.anyIPv4, listenPort)
      ..listen((Socket connectedClientSocket) {
        final clientSocket =
            ProtocolTcpIpSocket.fromConnectedSocket(connectedClientSocket)
              ..disconnected.listen(
                  (ConnectedData x) => _clientSocketDisconnected(x.target))
              ..receiveData.listen(dispatchReceiveData)
              ..setPacketRule(packetRule.clonePacketRule());

        _connectedSockets.add(clientSocket);

        dispatchConnected(clientSocket);
      });
  }

  @override
  Future<void> closeAsync() async {
    await _tcpListener.close();
    _tcpListener = null;

    final closeTasks = List<Future<void>>(0);

    if (_waitClientsTask != null) {
      closeTasks.add(_waitClientsTask.stopAsync());
    }

    for (final clientSocket in _connectedSockets) {
      await clientSocket.closeAsync();
      closeTasks.add(clientSocket.closeAsync());
    }

    _connectedSockets.clear();

    return Future.wait(closeTasks);
  }

  @override
  Future<void> sendAsync(Uint8List dataBuffer) {
    final sendTasks = List<Future<void>>(0);

    for (final clientSocket in _connectedSockets) {
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

    final protocolTcpIp = delivererProtocol as ProtocolTcpIpSocket;
    final foundIndex = _connectedSockets.indexOf(protocolTcpIp);

    if (foundIndex >= 0) {
      await protocolTcpIp.closeAsync();

      _connectedSockets.removeAt(foundIndex);

      dispatchDisconnected(protocolTcpIp);
    }
  }
}
