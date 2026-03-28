import 'package:universal_io/io.dart';
import 'dart:typed_data';

import '../connected_data.dart';
import 'objectdeliverer_protocol.dart';
import 'protocol_websocket.dart';

class ProtocolWebSocketServer extends ObjectDelivererProtocol {
  ProtocolWebSocketServer.fromParam(this.listenPort, {this.path = 'ws'});

  final List<ProtocolWebSocket> _connectedSockets = <ProtocolWebSocket>[];

  HttpServer? _httpServer;

  int listenPort;
  String path = 'ws';

  @override
  Future<void> start() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, listenPort);
    _httpServer!
        .where((request) => request.uri.path == '/$path')
        .transform(WebSocketTransformer())
        .listen((WebSocket connectedClientSocket) {
      final clientSocket =
          ProtocolWebSocket.fromConnectedSocket(connectedClientSocket)
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
    await _httpServer?.close();
    _httpServer = null;

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
    if (delivererProtocol is! ProtocolWebSocket) {
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
