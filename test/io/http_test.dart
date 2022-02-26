// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cancellation_token/cancellation_token.dart';
@TestOn('vm')
import 'package:cancellation_token_http/cancellable_http.dart' as http;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('http.', () {
    setUp(startServer);

    tearDown(stopServer);

    test('head', () async {
      var response = await http.head(serverUrl);
      expect(response.statusCode, equals(200));
      expect(response.body, equals(''));
    });

    test('get', () async {
      var response = await http.get(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('get with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.get(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('get with cancellation whilst receiving the response body', () async {
      var token = CancellationToken();
      expect(
        http.get(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('get with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.get(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('post', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('post with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.post(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('post with cancellation whilst receiving the response body', () async {
      var token = CancellationToken();
      expect(
        http.post(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('post with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.post(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('post with string', () async {
      var response = await http.post(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('post with bytes', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('post with fields', () async {
      var response = await http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('put', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('put with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.put(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('put with cancellation whilst receiving the response body', () async {
      var token = CancellationToken();
      expect(
        http.put(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('put with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.put(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('put with string', () async {
      var response = await http.put(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('put with bytes', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('put with fields', () async {
      var response = await http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('patch', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
    });

    test('patch with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.patch(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('patch with cancellation whilst receiving the response body',
        () async {
      var token = CancellationToken();
      expect(
        http.patch(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('patch with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.patch(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'Content-Type': 'text/plain',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('patch with string', () async {
      var response = await http.patch(serverUrl,
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          body: 'request body');
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
    });

    test('patch with bytes', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: [
        104,
        101,
        108,
        108,
        111
      ]);
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
    });

    test('patch with fields', () async {
      var response = await http.patch(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      }, body: {
        'some-field': 'value',
        'other-field': 'other value'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(equals({
            'method': 'PATCH',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
    });

    test('delete', () async {
      var response = await http.delete(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(response.statusCode, equals(200));
      expect(
          response.body,
          parse(allOf(
              containsPair('method', 'DELETE'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('delete with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.delete(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('delete with cancellation whilst receiving the response body',
        () async {
      var token = CancellationToken();
      expect(
        http.delete(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('delete with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.delete(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('read', () async {
      var response = await http.read(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });
      expect(
          response,
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('read with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.read(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('read with cancellation whilst receiving the response body', () async {
      var token = CancellationToken();
      expect(
        http.read(
          serverUrl.resolve('/delayed-close'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(seconds: 1), token.cancel);
    });

    test('read with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.read(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('read throws an error for a 4** status code', () {
      expect(http.read(serverUrl.resolve('/error')), throwsClientException);
    });

    test('readBytes', () async {
      var bytes = await http.readBytes(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'User-Agent': 'Dart'
      });

      expect(
          String.fromCharCodes(bytes),
          parse(allOf(
              containsPair('method', 'GET'),
              containsPair('path', '/'),
              containsPair(
                  'headers',
                  allOf(
                      containsPair('accept-encoding', ['gzip']),
                      containsPair('user-agent', ['Dart']),
                      containsPair('x-random-header', ['Value']),
                      containsPair('x-other-header', ['Other Value']))))));
    });

    test('readBytes with cancellation during request', () async {
      var token = CancellationToken();
      expect(
        http.readBytes(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
      Future.delayed(const Duration(milliseconds: 100), token.cancel);
    });

    test('readBytes with cancellation before request', () async {
      var token = CancellationToken()..cancel();
      expect(
        http.readBytes(
          serverUrl.resolve('/delayed'),
          headers: {
            'X-Random-Header': 'Value',
            'X-Other-Header': 'Other Value',
            'User-Agent': 'Dart'
          },
          cancellationToken: token,
        ),
        throwsA(isA<CancelledException>()),
      );
    });

    test('readBytes throws an error for a 4** status code', () {
      expect(
          http.readBytes(serverUrl.resolve('/error')), throwsClientException);
    });
  });
}
