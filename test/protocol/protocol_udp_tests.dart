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

Future<void> _testUDP(PacketRuleBase packetRule) async {
  final receiver = ProtocolUdpSocketReceiver.fromParam(50123)
    ..setPacketRule(packetRule.clonePacketRule());

  final sender = ProtocolUdpSocketSender.fromParam('localhost', 50123)
    ..setPacketRule(packetRule.clonePacketRule());

  {
    var counter = 2;
    final clientListener = receiver.connected.listen((x) => counter--);
    final serverListener = sender.connected.listen((x) => counter--);
    await receiver.start();

    await sender.start();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListener.cancel();
    await serverListener.cancel();
  }

  {
    final expected = Uint8List.fromList([1, 2, 3]);

    var counter = 100;
    final serverListener = receiver.receiveData.listen((x) {
      final expected2 = Uint8List.fromList([counter, 2, 3]);
      expect(x.buffer, expected2);
      counter--;
    });
    {
      for (var i = 100; i > 0; --i) {
        expected[0] = i;
        await sender.send(expected);
        await waitCounter(() => counter == i - 1);
      }

      if (await waitCounter(
            () => counter == 0,
            const Duration(seconds: 10),
          ) ==
          false) {
        fail('fail');
      }
    }

    await serverListener.cancel();
  }

  await receiver.close();
  await sender.close();
}

void main() {
  group('UDP', () {
    test('protocols', () async {
      await _testUDP(PacketRuleSizeBody.fromParam(4));
      await _testUDP(PacketRuleFixedLength.fromParam(3));
      await _testUDP(PacketRuleNodivision());
      await _testUDP(
        PacketRuleTerminate.fromParam(Uint8List.fromList([0xEE, 0xFF])),
      );
    });
  });
}
