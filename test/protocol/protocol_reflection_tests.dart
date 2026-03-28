import 'dart:async';
import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

Future<bool> waitCounter(
  bool Function() checkCondition, [
  Duration limitTime = const Duration(seconds: 1),
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
  group('ProtocolReflection', () {
    test('send and receive loopback', () async {
      final reflection = ProtocolReflection()
        ..setPacketRule(PacketRuleNodivision());

      var connectedCount = 0;
      reflection.connected.listen((x) => connectedCount++);

      await reflection.start();

      if (await waitCounter(() => connectedCount == 1) == false) {
        fail('connected event not fired');
      }

      final expected = Uint8List.fromList([1, 2, 3, 4, 5]);
      var receivedCount = 0;
      final receivedData = <Uint8List>[];

      reflection.receiveData.listen((x) {
        receivedData.add(x.buffer);
        receivedCount++;
      });

      await reflection.send(expected);

      if (await waitCounter(() => receivedCount == 1) == false) {
        fail('receive event not fired');
      }

      await expectLater(receivedData.length, 1);
      await expectLater(receivedData.first, expected);

      await reflection.dispose();
    });

    test('send and receive with PacketRuleSizeBody', () async {
      final reflection = ProtocolReflection()
        ..setPacketRule(PacketRuleSizeBody.fromParam(4));

      await reflection.start();

      final expected = Uint8List.fromList([10, 20, 30]);
      var receivedCount = 0;
      final receivedData = <Uint8List>[];

      reflection.receiveData.listen((x) {
        receivedData.add(x.buffer);
        receivedCount++;
      });

      await reflection.send(expected);

      if (await waitCounter(() => receivedCount == 1) == false) {
        fail('receive event not fired');
      }

      await expectLater(receivedData.length, 1);
      await expectLater(receivedData.first, expected);

      await reflection.dispose();
    });

    test('send and receive with PacketRuleFixedLength', () async {
      final reflection = ProtocolReflection()
        ..setPacketRule(PacketRuleFixedLength.fromParam(5));

      await reflection.start();

      final expected = Uint8List.fromList([1, 2, 3, 4, 5]);
      var receivedCount = 0;
      final receivedData = <Uint8List>[];

      reflection.receiveData.listen((x) {
        receivedData.add(x.buffer);
        receivedCount++;
      });

      await reflection.send(expected);

      if (await waitCounter(() => receivedCount == 1) == false) {
        fail('receive event not fired');
      }

      await expectLater(receivedData.length, 1);
      await expectLater(receivedData.first, expected);

      await reflection.dispose();
    });

    test('send and receive with PacketRuleTerminate', () async {
      final reflection = ProtocolReflection()
        ..setPacketRule(
            PacketRuleTerminate.fromParam(Uint8List.fromList([0xFF])));

      await reflection.start();

      final expected = Uint8List.fromList([1, 2, 3, 4, 5]);
      var receivedCount = 0;
      final receivedData = <Uint8List>[];

      reflection.receiveData.listen((x) {
        receivedData.add(x.buffer);
        receivedCount++;
      });

      await reflection.send(expected);

      if (await waitCounter(() => receivedCount == 1) == false) {
        fail('receive event not fired');
      }

      await expectLater(receivedData.length, 1);
      await expectLater(receivedData.first, expected);

      await reflection.dispose();
    });
  });
}
