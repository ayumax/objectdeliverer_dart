import 'dart:async';
import 'dart:typed_data';
import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';
import 'package:test/test.dart';

Future<bool> waitCounter(bool Function() checkCondition) {
  final completer = Completer<bool>(); // Completer<T>を作成する。

  Timer(const Duration(seconds: 1), () => completer.complete(false));

  Timer.periodic(const Duration(microseconds: 10), (timer) {
    if (checkCondition()) {
      completer.complete(true);
    }
  });

  return completer.future; // Completerの持つFutureオブジェクトを返す。
}

Future<void> _testTCPAsync(PacketRuleBase packetRule) async {
  final client = ProtocolTcpIpClient.fromParam('127.0.0.1', 9013,
      autoConnectAfterDisconnect: true)
    ..setPacketRule(packetRule.clonePacketRule());

  var server = ProtocolTcpIpServer.fromParam(9013)
    ..setPacketRule(packetRule.clonePacketRule());

  var counter = 2;
  client.connected.listen((x) => counter--);
  server.connected.listen((x) => counter--);
  await server.startAsync();

  await client.startAsync();

  if (await waitCounter(() => counter == 0) == false) {
    fail('fail tcp connected');
  }

  //     {
  //         var expected = new byte[] { 1, 2, 3 };

  //         using (var condition = new CountdownEvent(100))
  //         using (server.ReceiveData.Subscribe(x =>
  //         {
  //             var expected2 = new byte[] { (byte)condition.CurrentCount, 2, 3 };
  //             Assert.IsTrue(x.Buffer.ToArray().SequenceEqual(expected2));
  //             condition.Signal();
  //         }))
  //         {
  //             for (byte i = 100; i > 0; --i)
  //             {
  //                 expected[0] = i;
  //                 await client.SendAsync(expected);
  //             }

  //             if (!condition.Wait(1000))
  //             {
  //                 Assert.Fail();
  //             }
  //         }
  //     }

  //     {
  //         var expected = new byte[] { 1, 2, 3 };

  //         using (var condition = new CountdownEvent(100))
  //         using (client.ReceiveData.Subscribe(x =>
  //         {
  //             var expected2 = new byte[] { (byte)condition.CurrentCount, 2, 3 };
  //             Assert.IsTrue(x.Buffer.ToArray().SequenceEqual(expected2));
  //             condition.Signal();
  //         }))
  //         {
  //             for (byte i = 100; i > 0; --i)
  //             {
  //                 expected[0] = i;
  //                 await server.SendAsync(expected);
  //             }

  //             if (!condition.Wait(3000))
  //             {
  //                 Assert.Fail();
  //             }
  //         }
  //     }

  //     {
  //         using (var condition = new CountdownEvent(1))
  //         using (client.Disconnected.Subscribe(x => condition.Signal()))
  //         {
  //             await server.CloseAsync();

  //             if (!condition.Wait(1000))
  //             {
  //                 Assert.Fail();
  //             }
  //         }
  //     }

  //     {
  //         using (var condition = new CountdownEvent(1))
  //         using (client.Connected.Subscribe(x => condition.Signal()))
  //         {
  //             await server.StartAsync();

  //             if (!condition.Wait(1000))
  //             {
  //                 Assert.Fail();
  //             }
  //         }

  //         using (var condition = new CountdownEvent(1))
  //         using (server.Disconnected.Subscribe(x => condition.Signal()))
  //         {
  //             await client.CloseAsync();

  //             if (!condition.Wait(1000))
  //             {
  //                 Assert.Fail();
  //             }
  //         }
  //     }

  //     await client.CloseAsync();
  //     await server.CloseAsync();
  // }
}

void main() {
  group('TCPIP', () {
    test('size body', () async {
      await _testTCPAsync(PacketRuleSizeBody.fromParam(4));
    });

    test('fixed size', () async {
      await _testTCPAsync(PacketRuleFixedLength.fromParam(3));
    });

    test('terminate', () async {
      await _testTCPAsync(
          PacketRuleTerminate.fromParam(Uint8List.fromList([0xEE, 0xFF])));
    });
  });
}
