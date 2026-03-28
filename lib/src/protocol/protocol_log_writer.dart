import 'dart:io';
import 'dart:typed_data';

import 'objectdeliverer_protocol.dart';

class ProtocolLogWriter extends ObjectDelivererProtocol {
  ProtocolLogWriter.fromParam(this.filePath, {this.pathIsAbsolute = false});

  final String filePath;
  final bool pathIsAbsolute;

  RandomAccessFile? _writer;
  DateTime? _startTime;

  @override
  Future<void> start() async {
    await _closeWriter();

    final writePath = _resolvePath();

    final file = File(writePath);
    _writer = await file.open(mode: FileMode.writeOnly);

    _startTime = DateTime.now();

    dispatchConnected(this);
  }

  @override
  Future<void> close() async {
    await _closeWriter();
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {
    final writer = _writer;
    final startTime = _startTime;
    if (writer == null || startTime == null) return;

    final sendBuffer = packetRule.makeSendPacket(dataBuffer);

    final elapsed =
        DateTime.now().difference(startTime).inMilliseconds.toDouble();
    final elapsedBytes = _doubleToBytes(elapsed);
    final lengthBytes = _int32ToBytes(sendBuffer.length);

    writer.writeFromSync(elapsedBytes);
    writer.writeFromSync(lengthBytes);
    writer.writeFromSync(sendBuffer);
    await writer.flush();
  }

  Future<void> _closeWriter() async {
    final writer = _writer;
    if (writer == null) return;

    await writer.close();
    _writer = null;
  }

  String _resolvePath() {
    if (pathIsAbsolute) return filePath;
    return '${Directory.current.path}/$filePath';
  }

  static Uint8List _doubleToBytes(double value) {
    final bytes = ByteData(8);
    bytes.setFloat64(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }

  static Uint8List _int32ToBytes(int value) {
    final bytes = ByteData(4);
    bytes.setInt32(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }
}
