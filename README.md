# Dart Cancellation Token: HTTP

A fork of Dart's [HTTP package](https://pub.dev/packages/http) with request cancellation using [cancellation_token](https://pub.dev/packages/cancellation_token).

**Currently based on version 0.13.4 of the [HTTP package](https://pub.dev/packages/http/versions/0.13.4).**

## Using

This package keeps the same APIs as the base HTTP package, but with the addition of optional `cancellationToken` parameters.

```dart
import 'package:cancellation_token_http/cancellable_http.dart' as http;

var token = http.CancellationToken();
try {
  // A single CancellationToken can be used for multiple requests
  var readResponse = await http.read(
    Uri.parse('https://example.com/foobar.txt'),
    cancellationToken: token,
  );
  var postResponse = await http.post(
    Uri.parse('https://example.com/whatsit/create'),
    body: {'name': 'doodle', 'color': 'blue'},
    cancellationToken: token,
  );
  print('Read response: $readReponse');
  print('Post response status: ${response.statusCode}');
  print('Post response body: ${response.body}');
} on http.CancelledException {
  // If `token.cancel()` is called, the request will be cancelled and a
  // CancelledException will be thrown
  print('Request cancelled');
}
```

## Parsing JSON in an isolate

When paired with the [cancellation_token](https://pub.dev/packages/cancellation_token) package, you can use a single CancellationToken for the request and parsing the response in an isolate.

```dart
import 'package:cancellation_token/cancellation_token.dart';
import 'package:cancellation_token_http/cancellable_http.dart' as http;

Future<void> makeRequest() async {
  var token = CancellationToken();
  try {
    var response = await http.get(
      Uri.parse('https://example.com/bigjson'),
      cancellationToken: token,
    );
    var parsedResponse = cancellableCompute(
      _readAndParseJson,
      response.body,
      token,
    );
    print('Request and parse complete');
  } on CancelledException {
    // If `token.cancel()` is called, the request and response parsing will be
    // cancelled and a CancelledException will be thrown
    print('Request and parse cancelled');
  }
}

static ChunkyApiResponse _readAndParseJson(String json) {
  final Map<String, dynamic> decodedJson = jsonDecode(json);
  return ChunkyApiResponse.fromJson(decodedJson);
}
```
