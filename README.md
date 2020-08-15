# objectdeliverer_dart

## pub.dev
https://pub.dev/packages/objectdeliverer_dart

To install with pub.dev, just install the objectdeliverer_dart package:

https://pub.dev/packages/objectdeliverer_dart/install

## Description
ObjectDeliverer is a data transmission / reception library for dart.

It is a sister library of the same name for UE4.

https://github.com/ayumax/ObjectDeliverer

It has the following features.

+ Communication protocol, data division rule, serialization method can be switched by part replacement.
+ It is also possible to apply your own object serialization method

## Communication protocol
The following protocols can be used with built-in.
You can also add your own protocol.
+ TCP/IP Server(Connectable to multiple clients)
+ TCP/IP Client
+ UDP(Sender)
+ UDP(Receiver)

## Data division rule
The following rules are available for built-in split rules of transmitted and received data.
+ FixedSize  
	Example) In the case of fixed 1024 bytes
	![fixedlength](https://user-images.githubusercontent.com/8191970/56475737-7d999f00-64c7-11e9-8e9e-0182f1af8156.png)


+ Header(BodySize) + Body  
	Example) When the size area is 4 bytes  
	![sizeandbody](https://user-images.githubusercontent.com/8191970/56475796-6e672100-64c8-11e9-8cf0-6524f2899be0.png)


+ Split by terminal symbol  
	Example) When 0x00 is the end
	![terminate](https://user-images.githubusercontent.com/8191970/56475740-82f6e980-64c7-11e9-91a6-05d77cfdbd60.png)

## Serialization method
+ Byte Array
+ UTF-8 string
+ Object(Json)


# Quick Start
Create ObjectDelivererManager and create various communication paths by passing "Communication Protocol", "Packet Split Rule" and "Serialization Method" to the arguments of StartAsync method.

```cs
  // Create an ObjectDelivererManager
  final deliverer = ObjectDelivererManager<String>();

  // Watching for connection events
  deliverer.connected.listen((x) async {
    print('connected');

    // Sending data to a connected party
    await deliverer.sendAsync(Uint8List.fromList([0x00, 0x12]));
    await deliverer.sendAsync(Uint8List.fromList([0x00, 0x12, 0x23]));
  });

  // Watching for disconnection events
  deliverer.disconnected.listen((x) => print('disconnected'));

  // Watching for incoming events
  deliverer.receiveData.listen((x) {
    print('received buffer length = ${x.buffer.length}');
    print('received message = ${x.message}');
  });

  // Start the ObjectDelivererManager
  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), Utf8StringDeliveryBox());

  await Future.delayed(const Duration(milliseconds: 100));

  // Close ObjectDelivererManager
  await deliverer.close();

```

# Change communication protocol
You can switch to various communication protocols by changing the Protocol passed to the StartAsync method.

```cs
  // TCP/IP Client
  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  // TCP/IP Server
  await deliverer.startAsync(
      ProtocolTcpIpServer.fromParam(9013), PacketRuleFixedLength.fromParam(10));

  // UDP Sender
  await deliverer.startAsync(
      ProtocolUdpSocketSender.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  // UDP Receiver
  await deliverer.startAsync(ProtocolUdpSocketReceiver.fromParam(9013),
      PacketRuleFixedLength.fromParam(10));

```

# Change of data division rule
You can easily change the packet splitting rule.

```cs
  // FixedSize
  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10));

  // Header(BodySize) + Body
  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleSizeBody.fromParam(4, sizeBufferEndian: Endian.big));


  // Split by terminal symbol
  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleTerminate.fromParam(Uint8List.fromList([0xFE, 0xFF])));

  // Nodivision
  await deliverer.startAsync(
      ProtocolTcpIpClient.fromParam('127.0.0.1', 9013), PacketRuleNodivision());
```

# Change of Serialization method
Using DeliveryBox enables sending and receiving of non-binary data (character strings and objects).

```cs
  // UTF-8 string
  final deliverer = ObjectDelivererManager<String>();

  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), Utf8StringDeliveryBox());

  deliverer.receiveData.listen((x) => print(x.message));

  await deliverer.sendMessageAsync('ABCDEFG');
```

```cs
// Object
class SampleObj extends IJsonSerializable {
  SampleObj() {
    IJsonSerializable.addMakeInstanceFunction(SampleObj, (json) {
      final obj = SampleObj();
      prop = json['prop'] as int;
      stringProp = json['stringProp'] as String;
      return obj;
    });
  }
  int prop;
  String stringProp;

  String hoge() => '$prop$stringProp';

  @override
  Map<String, dynamic> toJson() => {'prop': prop, 'stringProp': stringProp};
}

  final deliverer = ObjectDelivererManager<SampleObj>();

  await deliverer.startAsync(ProtocolTcpIpClient.fromParam('127.0.0.1', 9013),
      PacketRuleFixedLength.fromParam(10), ObjectJsonDeliveryBox<SampleObj>());

  deliverer.receiveData.listen((x) => print(x.message.hoge()));

  final sampleObj = SampleObj()
    ..prop = 1
    ..stringProp = 'abc';
  await deliverer.sendMessageAsync(sampleObj);

```
