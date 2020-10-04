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

Future _testWebSocket(PacketRuleBase packetRule) async {
  final client = ProtocolWebSocketClient.fromParam('ws://127.0.0.1:53129/ws',
      autoConnectAfterDisconnect: true)
    ..setPacketRule(packetRule.clonePacketRule());

  final server = ProtocolWebSocketServer.fromParam(53129)
    ..setPacketRule(packetRule.clonePacketRule());

  {
    var counter = 2;
    final clientListner = client.connected.listen((x) => counter--);
    final serverListner = server.connected.listen((x) => counter--);
    await server.start();

    await client.start();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListner.cancel();
    await serverListner.cancel();
  }

  {
    final expected = Uint8List.fromList([1, 2, 3]);

    var counter = 100;
    final serverListner = server.receiveData.listen((x) {
      final expected2 = Uint8List.fromList([counter, 2, 3]);
      expect(x.buffer, expected2);
      counter--;
    });
    {
      for (var i = 100; i > 0; --i) {
        expected[0] = i;
        await client.send(expected);
        await waitCounter(() => counter == i - 1);
      }

      if (await waitCounter(() => counter == 0, const Duration(seconds: 10)) ==
          false) {
        fail('fail');
      }
    }

    await serverListner.cancel();
  }

  {
    final expected = Uint8List.fromList([1, 2, 3]);
    var counter = 100;
    final clientListner = client.receiveData.listen((x) {
      final expected2 = Uint8List.fromList([counter, 2, 3]);
      expect(x.buffer, expected2);
      counter--;
    });
    {
      for (var i = 100; i > 0; --i) {
        expected[0] = i;
        await server.send(expected);
        await waitCounter(() => counter == i - 1);
      }

      if (await waitCounter(() => counter == 0, const Duration(seconds: 10)) ==
          false) {
        fail('fail');
      }
    }

    await clientListner.cancel();
  }

  {
    var counter = 1;
    final clientListner = client.disconnected.listen((x) => counter--);
    await server.close();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListner.cancel();
  }

  {
    var counter = 1;
    final clientListner = client.connected.listen((x) => counter--);
    await server.start();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListner.cancel();
  }

  {
    var counter = 1;
    final serverListner = server.disconnected.listen((x) => counter--);
    await client.close();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await serverListner.cancel();
  }

  await client.close();
  await server.close();
}

void main() {
  group('WebSocket', () {
    test('protocols', () async {
      await _testWebSocket(PacketRuleSizeBody.fromParam(4));
      await _testWebSocket(PacketRuleFixedLength.fromParam(3));
      await _testWebSocket(
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xEE, 0xFF])));
    });
  });
}
