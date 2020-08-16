import 'protocol/objectdeliverer_protocol.dart';

/// Connect, disconnect event
class ConnectedData {
  ConnectedData.fromTarget(this.target);

  /// Event target.
  ObjectDelivererProtocol target;
}
