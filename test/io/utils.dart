// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cancellation_token_http/cancellable_http.dart';
import 'package:cancellation_token_http/src/utils.dart';
import 'package:test/test.dart';

export '../utils.dart';

/// The current server instance.
HttpServer? _server;

/// The URL for the current server instance.
Uri get serverUrl => Uri.parse('http://localhost:${_server!.port}');

/// Starts a new HTTP server.
Future<void> startServer() async {
  _server = (await HttpServer.bind('localhost', 0))
    ..listen((request) async {
      var path = request.uri.path;
      var response = request.response;

      if (path == '/error') {
        response
          ..statusCode = 400
          ..contentLength = 0;
        unawaited(response.close());
        return;
      }

      if (path == '/delayed') {
        await Future<void>.delayed(const Duration(seconds: 5));
        response
          ..statusCode = 400
          ..contentLength = 0;
        unawaited(response.close());
        return;
      }

      if (path == '/loop') {
        var n = int.parse(request.uri.query);
        response
          ..statusCode = 302
          ..headers
              .set('location', serverUrl.resolve('/loop?${n + 1}').toString())
          ..contentLength = 0;
        unawaited(response.close());
        return;
      }

      if (path == '/redirect') {
        response
          ..statusCode = 302
          ..headers.set('location', serverUrl.resolve('/').toString())
          ..contentLength = 0;
        unawaited(response.close());
        return;
      }

      if (path == '/no-content-length') {
        response
          ..statusCode = 200
          ..contentLength = -1
          ..write('body');
        unawaited(response.close());
        return;
      }

      // Catch errors if the connection is closed by the client
      final Uint8List requestBodyBytes;
      try {
        requestBodyBytes = await ByteStream(request).toBytes();
      } catch (_) {
        return;
      }

      var encodingName = request.uri.queryParameters['response-encoding'];
      var outputEncoding = encodingName == null
          ? ascii
          : requiredEncodingForCharset(encodingName);

      response.headers.contentType =
          ContentType('application', 'json', charset: outputEncoding.name);
      response.headers.set('single', 'value');

      dynamic requestBody;
      if (requestBodyBytes.isEmpty) {
        requestBody = null;
      } else if (request.headers.contentType?.charset != null) {
        var encoding =
            requiredEncodingForCharset(request.headers.contentType!.charset!);
        requestBody = encoding.decode(requestBodyBytes);
      } else {
        requestBody = requestBodyBytes;
      }

      final headers = <String, List<String>>{};

      request.headers.forEach((name, values) {
        // These headers are automatically generated by dart:io, so we don't
        // want to test them here.
        if (name == 'cookie' || name == 'host') return;

        headers[name] = values;
      });

      var content = <String, dynamic>{
        'method': request.method,
        'path': request.uri.path,
        if (requestBody != null) 'body': requestBody,
        'headers': headers,
      };

      var body = json.encode(content);
      if (path == '/delayed-close') {
        response.write(body);
        await Future<void>.delayed(const Duration(seconds: 5));
      } else {
        response
          ..contentLength = body.length
          ..write(body);
      }
      unawaited(response.close());
    });
}

/// Stops the current HTTP server.
void stopServer() {
  if (_server != null) {
    _server!.close();
    _server = null;
  }
}

/// A matcher for functions that throw HttpException.
Matcher get throwsClientException =>
    throwsA(const TypeMatcher<ClientException>());

/// A matcher for functions that throw SocketException.
final Matcher throwsSocketException =
    throwsA(const TypeMatcher<SocketException>());
