import 'dart:async';
import 'dart:io';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

Future<bool> waitCounter(
  bool Function() checkCondition, [
  Duration limitTime = const Duration(seconds: 5),
]) {
  final completer = Completer<bool>();

  late Timer onceTimer;
  late Timer periodicTimer;

  onceTimer = Timer(limitTime, () {
    completer.complete(false);
    onceTimer.cancel();
    periodicTimer.cancel();
  });

  periodicTimer = Timer.periodic(const Duration(microseconds: 10), (timer) {
    if (checkCondition()) {
      completer.complete(true);
      onceTimer.cancel();
      periodicTimer.cancel();
    }
  });

  return completer.future;
}

void main() {
  group('ProtocolLogWriter/Reader', () {
    test('write and read log with PacketRuleSizeBody', () async {
      const logFilePath = 'test_log.bin';
      final absolutePath =
          '${Directory.current.path}/$logFilePath';
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }

      final deliveryBox = Utf8StringDeliveryBox();

      final writer = ProtocolLogWriter.fromParam(logFilePath)
        ..setPacketRule(PacketRuleSizeBody.fromParam(4));

      var writerConnectedCount = 0;
      writer.connected.listen((x) => writerConnectedCount++);

      await writer.start();

      if (await waitCounter(() => writerConnectedCount == 1) == false) {
        fail('writer connected event not fired');
      }

      final sendBuffer1 = deliveryBox.makeSendBuffer('AAA');
      await writer.send(sendBuffer1);

      await Future<void>.delayed(const Duration(milliseconds: 300));

      final sendBuffer2 = deliveryBox.makeSendBuffer('BBB');
      await writer.send(sendBuffer2);

      await Future<void>.delayed(const Duration(milliseconds: 700));

      final sendBuffer3 = deliveryBox.makeSendBuffer('CCC');
      await writer.send(sendBuffer3);

      await writer.close();

      final receivedStrings = <String>[];

      final reader = ProtocolLogReader.fromParam(logFilePath,
          cutFirstInterval: true)
        ..setPacketRule(PacketRuleSizeBody.fromParam(4));

      reader.receiveData.listen((x) {
        final msg = deliveryBox.bufferToMessage(x.buffer);
        receivedStrings.add(msg);
      });

      await reader.start();

      if (await waitCounter(() => receivedStrings.length == 3,
              const Duration(seconds: 5)) ==
          false) {
        fail('did not receive all 3 strings (got ${receivedStrings.length})');
      }

      await expectLater(receivedStrings.length, 3);
      await expectLater(receivedStrings[0], 'AAA');
      await expectLater(receivedStrings[1], 'BBB');
      await expectLater(receivedStrings[2], 'CCC');

      await reader.close();

      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
