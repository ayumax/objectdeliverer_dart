import 'package:universal_io/io.dart';
import 'dart:typed_data';

import '../connected_data.dart';
import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

/// TCP/IP Server protocol
class ProtocolTcpIpServer extends ObjectDelivererProtocol {
  ProtocolTcpIpServer.fromParam(this.listenPort);

  final List<ProtocolTcpIpSocket> _connectedSockets = <ProtocolTcpIpSocket>[];

  ServerSocket _tcpListener;

  int listenPort;

  @override
  Future start() async {
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
  Future close() async {
    await _tcpListener.close();
    _tcpListener = null;

    final closeTasks = <Future>[];

    for (final clientSocket in _connectedSockets) {
      closeTasks.add(clientSocket.close());
    }

    _connectedSockets.clear();

    return Future.wait(closeTasks);
  }

  @override
  Future send(Uint8List dataBuffer) {
    final sendTasks = <Future>[];

    for (final clientSocket in _connectedSockets) {
      sendTasks.add(clientSocket.send(dataBuffer));
    }

    return Future.wait(sendTasks);
  }

  Future _clientSocketDisconnected(
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
      await protocolTcpIp.close();

      _connectedSockets.removeAt(foundIndex);

      dispatchDisconnected(protocolTcpIp);
    }
  }
}
