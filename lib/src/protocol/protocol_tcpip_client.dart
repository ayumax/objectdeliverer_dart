import 'dart:io';
import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpClient extends ProtocolTcpIpSocket {
  ProtocolTcpIpClient.fromParam(this.ipAddress, this.port,
      {this.autoConnectAfterDisconnect});

  Future _connectTask;

  String ipAddress = '127.0.0.1';

  int port;

  bool autoConnectAfterDisconnect = false;

  bool _isSelfClose = false;

  @override
  Future startAsync() async {
    await super.startAsync();

    // ignore: unawaited_futures
    _startConnect();
  }

  @override
  Future closeAsync() async {
    _isSelfClose = true;

    await super.closeAsync();

    await _connectTask;
  }

  @override
  void dispatchDisconnected(ObjectDelivererProtocol delivererProtocol) {
    super.dispatchDisconnected(delivererProtocol);

    if (autoConnectAfterDisconnect) {
      _startConnect();
    }
  }

  Future _startConnect() async {
    //await closeAsync();

    Future _connectAsync() async {
      _isSelfClose = false;

      ipClient = null;

      while (_isSelfClose == false) {
        try {
          await startConnect(ipAddress, port);

          break;
        } on SocketException {
          // Wait a minute and then try to reconnect.
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // ignore: join_return_with_assignment
    _connectTask = _connectAsync();
    return _connectTask;
  }
}
