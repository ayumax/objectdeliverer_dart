import 'package:universal_io/io.dart';
import 'dart:typed_data';

import '../connected_data.dart';
import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpServer extends ObjectDelivererProtocol {
  ProtocolTcpIpServer.fromParam(this.listenPort);

  final List<ProtocolTcpIpSocket> _connectedSockets = <ProtocolTcpIpSocket>[];

  ServerSocket? _tcpListener;

  int listenPort;

  @override
  Future<void> start() async {
    _tcpListener = await ServerSocket.bind(InternetAddress.anyIPv4, listenPort)
      ..listen((Socket connectedClientSocket) {
        final clientSocket =
            ProtocolTcpIpSocket.fromConnectedSocket(connectedClientSocket)
              ..disconnected.listen(
                (ConnectedData x) => _clientSocketDisconnected(x.target),
              )
              ..receiveData.listen(dispatchReceiveData)
              ..setPacketRule(packetRule.clonePacketRule());

        _connectedSockets.add(clientSocket);

        dispatchConnected(clientSocket);
      });
  }

  @override
  Future<void> close() async {
    await _tcpListener?.close();
    _tcpListener = null;

    final closeTasks = <Future<void>>[];

    for (final clientSocket in _connectedSockets) {
      closeTasks.add(clientSocket.close());
    }

    _connectedSockets.clear();

    await Future.wait(closeTasks);
  }

  @override
  Future<void> send(Uint8List dataBuffer) {
    final sendTasks = <Future<void>>[];

    for (final clientSocket in _connectedSockets) {
      sendTasks.add(clientSocket.send(dataBuffer));
    }

    return Future.wait(sendTasks);
  }

  Future<void> _clientSocketDisconnected(
    ObjectDelivererProtocol delivererProtocol,
  ) async {
    if (delivererProtocol is! ProtocolTcpIpSocket) {
      return;
    }

    final foundIndex = _connectedSockets.indexOf(delivererProtocol);

    if (foundIndex >= 0) {
      await delivererProtocol.close();

      _connectedSockets.removeAt(foundIndex);

      dispatchDisconnected(delivererProtocol);
    }
  }
}
