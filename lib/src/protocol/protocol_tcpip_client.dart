import 'package:universal_io/io.dart';
import 'protocol_tcpip_socket.dart';

class ProtocolTcpIpClient extends ProtocolTcpIpSocket {
  ProtocolTcpIpClient.fromParam(
    this.ipAddress,
    this.port, {
    this.autoConnectAfterDisconnect = false,
  });

  Future<void>? _connectTask;

  String ipAddress = '127.0.0.1';

  int port;

  bool autoConnectAfterDisconnect;

  bool _isSelfClose = false;

  @override
  Future<void> start() async {
    await super.start();

    _startConnect();
  }

  @override
  Future<void> close() async {
    _isSelfClose = true;

    await super.close();

    await _connectTask;
  }

  Future<void> _startConnect() async {
    Future<void> connect() async {
      _isSelfClose = false;

      ipClient = null;

      while (_isSelfClose == false) {
        try {
          await startConnect(ipAddress, port);

          break;
        } on SocketException {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }

    _connectTask = connect();
  }

  @override
  void onDone() async {
    super.onDone();

    if (_isSelfClose == false && autoConnectAfterDisconnect) {
      _startConnect();
    }
  }
}
