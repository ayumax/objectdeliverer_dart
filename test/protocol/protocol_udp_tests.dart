import 'dart:async';
import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

Future<bool> waitCounter(bool Function() checkCondition,
    [Duration limitTime = const Duration(seconds: 1)]) {
  final completer = Completer<bool>(); // Completer<T>を作成する。

  Timer onceTimer;
  Timer periodicTimer;

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

  return completer.future; // Completerの持つFutureオブジェクトを返す。
}

Future _testUDP(PacketRuleBase packetRule) async {
  final receiver = ProtocolUdpSocketReceiver.fromParam(50123)
    ..setPacketRule(packetRule.clonePacketRule());

  final sender = ProtocolUdpSocketSender.fromParam('localhost', 50123)
    ..setPacketRule(packetRule.clonePacketRule());

  {
    var counter = 2;
    final clientListner = receiver.connected.listen((x) => counter--);
    final serverListner = sender.connected.listen((x) => counter--);
    await receiver.start();

    await sender.start();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListner.cancel();
    await serverListner.cancel();
  }

  {
    final expected = Uint8List.fromList([1, 2, 3]);

    var counter = 100;
    final serverListner = receiver.receiveData.listen((x) {
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

      if (await waitCounter(() => counter == 0, const Duration(seconds: 10)) ==
          false) {
        fail('fail');
      }
    }

    await serverListner.cancel();
  }

  await receiver.close();
  await sender.close();
}

void main() {
  group('UDP', () {
    test('size body', () async {
      await _testUDP(PacketRuleSizeBody.fromParam(4));
    });

    test('fixed size', () async {
      await _testUDP(PacketRuleFixedLength.fromParam(3));
    });

    test('no division', () async {
      await _testUDP(PacketRuleNodivision());
    });

    test('terminate', () async {
      await _testUDP(
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xEE, 0xFF])));
    });
  });
}
