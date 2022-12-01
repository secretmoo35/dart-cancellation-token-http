import 'package:cancellation_token_http/http.dart';
import 'package:http_client_conformance_tests/http_client_conformance_tests.dart';
import 'package:test/test.dart';

class MyHttpClient extends BaseClient {
  @override
  Future<StreamedResponse> send(
    BaseRequest request, {
    CancellationToken? cancellationToken,
  }) async {
    // Your implementation here.
    throw UnsupportedError('implement this method');
  }
}

void main() {
  group('client conformance tests', () {
    testAll(MyHttpClient());
  });
}
