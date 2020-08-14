import 'dart:io';
import 'objectdeliverer_protocol.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpClient extends ProtocolTcpIpSocket {
  ProtocolTcpIpClient.fromParam(this.ipAddress, this.port,
      {this.autoConnectAfterDisconnect});

  Future<void> _connectTask;

  String ipAddress = '127.0.0.1';

  int port;

  bool autoConnectAfterDisconnect = false;

  bool _isSelfClose = false;

  @override
  Future<void> startAsync() async {
    await super.startAsync();

    _startConnect();
  }

  @override
  Future<void> closeAsync() async {
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

  void _startConnect() {
    Future<void> _connectAsync() async {
      await closeAsync();
      _isSelfClose = false;

      ipClient = null;

      while (_isSelfClose == false) {
        try {
          await startConnect(ipAddress, port);

          break;
        } on SocketException {
          // Wait a minute and then try to reconnect.
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    _connectTask = _connectAsync();
  }
}
