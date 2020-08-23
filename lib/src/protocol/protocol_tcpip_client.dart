import 'package:universal_io/io.dart';
import 'protocol_tcpip_socket.dart';

/// TCP/IP Client protocol
class ProtocolTcpIpClient extends ProtocolTcpIpSocket {
  ProtocolTcpIpClient.fromParam(this.ipAddress, this.port,
      {this.autoConnectAfterDisconnect});

  Future _connectTask;

  String ipAddress = '127.0.0.1';

  int port;

  bool autoConnectAfterDisconnect = false;

  bool _isSelfClose = false;

  @override
  Future start() async {
    await super.start();

    // ignore: unawaited_futures
    _startConnect();
  }

  @override
  Future close() async {
    _isSelfClose = true;

    await super.close();

    await _connectTask;
  }

  Future _startConnect() async {
    Future _connect() async {
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

    _connectTask = _connect();
    return _connectTask;
  }

  @override
  void onDone() async {
    super.onDone();

    if (_isSelfClose == false && autoConnectAfterDisconnect) {
      // ignore: unawaited_futures
      _startConnect();
    }
  }
}
