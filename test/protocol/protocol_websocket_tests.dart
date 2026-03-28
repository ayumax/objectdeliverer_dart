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

Future<void> _testWebSocket(PacketRuleBase packetRule) async {
  final client = ProtocolWebSocketClient.fromParam(
    'ws://127.0.0.1:53130/ws',
    autoConnectAfterDisconnect: true,
  )..setPacketRule(packetRule.clonePacketRule());

  final server = ProtocolWebSocketServer.fromParam(53130)
    ..setPacketRule(packetRule.clonePacketRule());

  {
    var counter = 2;
    final clientListener = client.connected.listen((x) => counter--);
    final serverListener = server.connected.listen((x) => counter--);
    await server.start();

    await client.start();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListener.cancel();
    await serverListener.cancel();
  }

  {
    final expected = Uint8List.fromList([1, 2, 3]);

    var counter = 100;
    final serverListener = server.receiveData.listen((x) {
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

  {
    final expected = Uint8List.fromList([1, 2, 3]);
    var counter = 100;
    final clientListener = client.receiveData.listen((x) {
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

      if (await waitCounter(
            () => counter == 0,
            const Duration(seconds: 10),
          ) ==
          false) {
        fail('fail');
      }
    }

    await clientListener.cancel();
  }

  {
    var counter = 1;
    final clientListener = client.disconnected.listen((x) => counter--);
    await server.close();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await clientListener.cancel();
  }

  {
    var counter = 1;
    final clientListener = client.connected.listen((x) => counter--);
    await server.start();

    if (await waitCounter(
          () => counter == 0,
          const Duration(seconds: 5),
        ) ==
        false) {
      fail('fail');
    }

    await clientListener.cancel();
  }

  {
    var counter = 1;
    final serverListener = server.disconnected.listen((x) => counter--);
    await client.close();

    if (await waitCounter(() => counter == 0) == false) {
      fail('fail');
    }

    await serverListener.cancel();
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
        PacketRuleTerminate.fromParam(Uint8List.fromList([0xEE, 0xFF])),
      );
    });
  });
}
