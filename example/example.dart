import 'dart:typed_data';

import 'package:objectdeliverer_dart/objectdeliverer_dart.dart';

Future quickStart() async {
  // Create an ObjectDelivererManager
  final deliverer = ObjectDelivererManager<String>();

  // Watching for connection events
  deliverer.connected.listen((x) async {
    print('connected');

    // Sending data to a connected party
    await deliverer.send(Uint8List.fromList([0x00, 0x12]));
    await deliverer.send(Uint8List.fromList([0x00, 0x12, 0x23]));
  });

  // Watching for disconnection events
  deliverer.disconnected.listen((x) => print('disconnected'));

  // Watching for incoming events
  deliverer.receiveData.listen((x) {
    print('received buffer length = ${x.buffer.length}');
    print('received message = ${x.message}');
  });

  // Start the ObjectDelivererManager
  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), Utf8StringDeliveryBox());

  await Future.delayed(const Duration(milliseconds: 100));

  // Close ObjectDelivererManager
  await deliverer.close();
}

Future changeCommunicationProtocol() async {
  final deliverer = ObjectDelivererManager<String>();

  // TCP/IP Client
  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  await deliverer.close();

  // TCP/IP Server
  await deliverer.start(
      ProtocolTcpIpServer.fromParam(9013), PacketRuleFixedLength.fromParam(10));

  await deliverer.close();

  // UDP Sender
  await deliverer.start(ProtocolUdpSocketSender.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  await deliverer.close();

  // UDP Receiver
  await deliverer.start(ProtocolUdpSocketReceiver.fromParam(9013),
      PacketRuleFixedLength.fromParam(10));

  await deliverer.close();
}

Future changeOfDataDivisionRule() async {
  final deliverer = ObjectDelivererManager<String>();

  // FixedSize
  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  await deliverer.close();

  // Header(BodySize) + Body
  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.big));

  await deliverer.close();

  // Split by terminal symbol
  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xFF])));

  await deliverer.close();

  // Nodivision
  await deliverer.start(
      ProtocolTcpIpClient.fromParam('127.0.0.1', 9013), PacketRuleNodivision());

  await deliverer.close();
}

Future changeOfSerializationMethodString() async {
  // UTF-8 string
  final deliverer = ObjectDelivererManager<String>();

  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), Utf8StringDeliveryBox());

  deliverer.receiveData.listen((x) => print(x.message));

  await deliverer.sendMessage('ABCDEFG');

  await Future.delayed(const Duration(milliseconds: 100));

  await deliverer.close();
}

// Object
class SampleObj extends IJsonSerializable {
  int prop;
  String stringProp;

  String hoge() => '$prop$stringProp';

  @override
  Map<String, dynamic> toJson() => {'prop': prop, 'stringProp': stringProp};
}

Future changeOfSerializationMethodObject() async {
  IJsonSerializable.addMakeInstanceFunction(SampleObj, (json) {
    final obj = SampleObj()
      ..prop = json['prop'] as int
      ..stringProp = json['stringProp'] as String;
    return obj;
  });

  final deliverer = ObjectDelivererManager<SampleObj>();

  await deliverer.start(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), ObjectJsonDeliveryBox<SampleObj>());

  deliverer.receiveData.listen((x) => print(x.message.hoge()));

  final sampleObj = SampleObj()
    ..prop = 1
    ..stringProp = 'abc';
  await deliverer.sendMessage(sampleObj);

  await Future.delayed(const Duration(milliseconds: 100));

  await deliverer.close();
}

Future main() async {
  await quickStart();
}
