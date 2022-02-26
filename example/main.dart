import 'dart:async';
import 'dart:convert' as convert;

import 'package:cancellation_token/cancellation_token.dart';
import 'package:cancellation_token_http/cancellable_http.dart' as http;

// This example uses the Google Books API to search for books about http.
// https://developers.google.com/books/docs/overview
void main(List<String> arguments) async {
  var url =
      Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});

  await standardRequest(url);
  await manualCancelRequest(url);
  await timeoutCancelRequest(url);
}

/// Example of request without cancellation.
Future<void> standardRequest(Uri url) async {
  print('Performing request without cancellation...');

  // Await the http get response, then decode the json-formatted response
  var response = await http.get(url);
  if (response.statusCode == 200) {
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    var itemCount = jsonResponse['totalItems'];
    print('Number of books about http: $itemCount.');
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
}

/// Example of request cancellation using a [CancellationToken].
Future<void> manualCancelRequest(Uri url) async {
  print('Performing request with a manual cancellation...');

  // This token will only cancel the request when `.cancel()` is called
  var cancellationToken = http.CancellationToken()..cancel();

  // Await the http get response, then decode the json-formatted response
  try {
    var response = await http.get(url, cancellationToken: cancellationToken);
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var itemCount = jsonResponse['totalItems'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  } on CancelledException {
    print('Request cancelled manually');
  }
}

/// Example of request cancellation using a [TimeoutCancellationToken].
Future<void> timeoutCancelRequest(Uri url) async {
  print('Performing request with a 5 second timeout cancellation...');

  // This token will cancel the request after 5 seconds
  var cancellationToken =
      http.TimeoutCancellationToken(const Duration(seconds: 5));

  // Await the http get response, then decode the json-formatted response
  try {
    var response = await http.get(url, cancellationToken: cancellationToken);
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var itemCount = jsonResponse['totalItems'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  } on TimeoutException {
    print('Request cancelled by timeout');
  }
}
