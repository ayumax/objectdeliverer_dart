import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';

Future<void> quickStart() async {
  final deliverer = ObjectDelivererManager<String>();

  deliverer.connected.listen((x) async {
    print('connected');

    await deliverer.send(Uint8List.fromList([0x00, 0x12]));
    await deliverer.send(Uint8List.fromList([0x00, 0x12, 0x23]));
  });

  deliverer.disconnected.listen((x) => print('disconnected'));

  deliverer.receiveData.listen((x) {
    print('received buffer length = ${x.buffer.length}');
    print('received message = ${x.message}');
  });

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
    Utf8StringDeliveryBox(),
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));

  await deliverer.close();
}

Future<void> changeCommunicationProtocol() async {
  final deliverer = ObjectDelivererManager<String>();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolTcpIpServer.fromParam(9013),
    PacketRuleFixedLength.fromParam(10),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolUdpSocketSender.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolUdpSocketReceiver.fromParam(9013),
    PacketRuleFixedLength.fromParam(10),
  );

  await deliverer.close();
}

Future<void> changeOfDataDivisionRule() async {
  final deliverer = ObjectDelivererManager<String>();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.big),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xFF])),
  );

  await deliverer.close();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleNodivision(),
  );

  await deliverer.close();
}

Future<void> changeOfSerializationMethodString() async {
  final deliverer = ObjectDelivererManager<String>();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
    Utf8StringDeliveryBox(),
  );

  deliverer.receiveData.listen((x) => print(x.message));

  await deliverer.sendMessage('ABCDEFG');

  await Future<void>.delayed(const Duration(milliseconds: 100));

  await deliverer.close();
}

class SampleObj extends IJsonSerializable {
  late int prop;
  late String stringProp;

  String hoge() => '$prop$stringProp';

  @override
  Map<String, dynamic> toJson() => {'prop': prop, 'stringProp': stringProp};
}

Future<void> changeOfSerializationMethodObject() async {
  IJsonSerializable.addMakeInstanceFunction(SampleObj, (json) {
    final obj = SampleObj()
      ..prop = json['prop'] as int
      ..stringProp = json['stringProp'] as String;
    return obj;
  });

  final deliverer = ObjectDelivererManager<SampleObj>();

  await deliverer.start(
    ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
    PacketRuleFixedLength.fromParam(10),
    ObjectJsonDeliveryBox<SampleObj>(),
  );

  deliverer.receiveData.listen((x) => print(x.message?.hoge()));

  final sampleObj = SampleObj()
    ..prop = 1
    ..stringProp = 'abc';
  await deliverer.sendMessage(sampleObj);

  await Future<void>.delayed(const Duration(milliseconds: 100));

  await deliverer.close();
}

Future<void> main() async {
  await quickStart();
}
