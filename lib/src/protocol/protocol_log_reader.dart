import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../deliver_data.dart';
import '../utils/grow_buffer.dart';
import '../utils/polling_task.dart';
import 'objectdeliverer_protocol.dart';

class ProtocolLogReader extends ObjectDelivererProtocol {
  ProtocolLogReader.fromParam(this.filePath,
      {this.pathIsAbsolute = false, this.cutFirstInterval = true});

  final String filePath;
  final bool pathIsAbsolute;
  final bool cutFirstInterval;

  RandomAccessFile? _reader;
  PollingTask? _pollingTask;
  DateTime? _startTime;
  double _currentLogTime = -1;
  GrowBuffer _readBuffer = GrowBuffer();
  int _fileLength = 0;
  int _filePosition = 0;
  bool _isFirst = true;

  @override
  Future<void> start() async {
    await _closeReader();

    final readPath = _resolvePath();

    final file = File(readPath);
    if (!await file.exists()) return;

    _reader = await file.open(mode: FileMode.read);
    _fileLength = await _reader!.length();
    _filePosition = 0;

    _startTime = DateTime.now();
    _currentLogTime = -1;
    _isFirst = true;
    _readBuffer = GrowBuffer();

    _pollingTask = PollingTask.fromAction(_readData);

    dispatchConnected(this);
  }

  @override
  Future<void> close() async {
    final task = _pollingTask;
    if (task != null) {
      await task.stop();
      _pollingTask = null;
    }

    await _closeReader();
  }

  @override
  Future<void> send(Uint8List dataBuffer) async {}

  Future<bool> _readData() async {
    final reader = _reader;
    if (reader == null) return false;

    while (_hasMoreData() || _currentLogTime >= 0) {
      if (_currentLogTime >= 0) {
        final nowTime =
            DateTime.now().difference(_startTime!).inMilliseconds.toDouble();

        if (_currentLogTime > nowTime) break;

        final size = _readBuffer.length;
        final wantSize = packetRule.wantSize;

        if (wantSize > 0 && size < wantSize) return true;

        var offset = 0;

        while (size > 0) {
          final ws = packetRule.wantSize;
          final receiveSize = ws == 0 ? size : ws;
          final receiveBuffer = _readBuffer.toBytes(offset, receiveSize);
          offset += receiveSize;
          final remaining = size - offset;

          for (final packet in packetRule.makeReceivedPacket(receiveBuffer)) {
            dispatchReceiveData(
                DeliverRawData.fromSenderAndBuffer(this, packet));
          }

          if (remaining <= 0) break;
        }

        _currentLogTime = -1;
      }

      final remainSize = _fileLength - _filePosition;
      if (remainSize < 8) return false;

      _currentLogTime = await _readDouble(reader);

      if (_isFirst && cutFirstInterval) {
        _startTime = _startTime!.subtract(
            Duration(milliseconds: _currentLogTime.round()));
      }

      _isFirst = false;

      final remainAfterTime = _fileLength - _filePosition;
      if (remainAfterTime < 4) return false;

      final bufferSize = await _readInt32(reader);

      final remainAfterSize = _fileLength - _filePosition;
      if (remainAfterSize < bufferSize) return false;

      final dataBytes = await _readBytes(reader, bufferSize);
      _readBuffer = GrowBuffer()..add(dataBytes);
    }

    return true;
  }

  bool _hasMoreData() => _filePosition < _fileLength;

  Future<double> _readDouble(RandomAccessFile reader) async {
    final bytes = await _readBytes(reader, 8);
    final byteData = ByteData.sublistView(bytes);
    return byteData.getFloat64(0, Endian.little);
  }

  Future<int> _readInt32(RandomAccessFile reader) async {
    final bytes = await _readBytes(reader, 4);
    final byteData = ByteData.sublistView(bytes);
    return byteData.getInt32(0, Endian.little);
  }

  Future<Uint8List> _readBytes(RandomAccessFile reader, int count) async {
    final bytes = Uint8List(count);
    await reader.readInto(bytes);
    _filePosition += count;
    return bytes;
  }

  Future<void> _closeReader() async {
    final reader = _reader;
    if (reader == null) return;

    await reader.close();
    _reader = null;
  }

  String _resolvePath() {
    if (pathIsAbsolute) return filePath;
    return '${Directory.current.path}/$filePath';
  }
}
