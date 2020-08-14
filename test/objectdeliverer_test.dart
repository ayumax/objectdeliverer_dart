import 'deliverybox/object_deliverybox_using_json_tests.dart'
    as object_deliverybox_using_json;
import 'deliverybox/utf8string_deliverybox_tests.dart'
    as utf8string_deliverybox;
import 'packetrule/packetrule_fixedlength_tests.dart' as packetrule_fixedlength;
import 'packetrule/packetrule_nodivision_tests.dart' as packetrule_nodivision;
import 'packetrule/packetrule_sizebody_tests.dart' as packetrule_sizebody;
import 'packetrule/packetrule_terminate_tests.dart' as packetrule_terminate;
import 'protocol/protocol_tcpip_client_tests.dart' as protocol_tcpip_client;
import 'utils/grow_buffer_tests.dart' as grow_buffer;

void main() {
  object_deliverybox_using_json.main();
  utf8string_deliverybox.main();
  packetrule_fixedlength.main();
  packetrule_nodivision.main();
  packetrule_sizebody.main();
  packetrule_terminate.main();
  grow_buffer.main();
  protocol_tcpip_client.main();
}
