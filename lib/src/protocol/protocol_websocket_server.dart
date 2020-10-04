import 'package:universal_io/io.dart';
import 'dart:typed_data';

import '../connected_data.dart';
import 'objectdeliverer_protocol.dart';
import 'protocol_websocket.dart';

/// WebSocket Server protocol
class ProtocolWebSocketServer extends ObjectDelivererProtocol {
  ProtocolWebSocketServer.fromParam(this.listenPort, {this.path = 'ws'});

  final List<ProtocolWebSocket> _connectedSockets = <ProtocolWebSocket>[];

  HttpServer _httpServer;

  int listenPort;
  String path = 'ws';

  @override
  Future start() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, listenPort)
      ..where((request) => request.uri.path == '/$path')
          .transform(WebSocketTransformer())
          .listen((WebSocket connectedClientSocket) {
        final clientSocket =
            ProtocolWebSocket.fromConnectedSocket(connectedClientSocket)
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
    await _httpServer.close();
    _httpServer = null;

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

    if (delivererProtocol is ProtocolWebSocket == false) {
      return;
    }

    final protocolWebSocket = delivererProtocol as ProtocolWebSocket;
    final foundIndex = _connectedSockets.indexOf(protocolWebSocket);

    if (foundIndex >= 0) {
      await protocolWebSocket.close();

      _connectedSockets.removeAt(foundIndex);

      dispatchDisconnected(protocolWebSocket);
    }
  }
}
