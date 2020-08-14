import 'dart:typed_data';

import '../utils/grow_buffer.dart';
import 'packetrule_base.dart';

class PacketRuleTerminate extends PacketRuleBase {
  PacketRuleTerminate.fromParam(this.terminate);

  final GrowBuffer _bufferForSend = GrowBuffer();
  final GrowBuffer _receiveTempBuffer = GrowBuffer();
  final GrowBuffer _bufferForReceive = GrowBuffer();

  Uint8List terminate = Uint8List(0);

  @override
  int get wantSize => 0;

  @override
  void initialize() {
    _bufferForSend.setBufferSize(0);
    _receiveTempBuffer.setBufferSize(0);
    _bufferForReceive.setBufferSize(0);
  }

  @override
  Uint8List makeSendPacket(Uint8List bodyBuffer) {
    _bufferForSend..add(bodyBuffer)..add(terminate);

    return _bufferForSend.memoryBuffer;
  }

  @override
  Iterable<Uint8List> makeReceivedPacket(Uint8List dataBuffer) sync* {
    if (wantSize > 0 && dataBuffer.length != wantSize) {
      return;
    }

    _receiveTempBuffer.add(dataBuffer);

    var findIndex = -1;

    // ignore: literal_only_boolean_expressions
    while (true) {
      for (var i = 0; i <= _receiveTempBuffer.length - terminate.length; ++i) {
        var notEqual = false;
        for (var j = 0; j < terminate.length; ++j) {
          if (_receiveTempBuffer.memoryBuffer[i + j] != terminate[j]) {
            notEqual = true;
            break;
          }
        }

        if (notEqual == false) {
          findIndex = i;
          break;
        }
      }

      if (findIndex == -1) {
        return;
      }

      _bufferForReceive
        ..setBufferSize(findIndex)
        ..copyFrom(_receiveTempBuffer.takeBytes(0, findIndex));

      yield _bufferForReceive.toAllBytes();

      _receiveTempBuffer.removeRangeStart(findIndex + terminate.length);

      findIndex = -1;
    }
  }

  @override
  PacketRuleBase clonePacketRule() => PacketRuleTerminate.fromParam(terminate);
}
