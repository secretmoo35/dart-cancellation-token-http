import 'dart:async';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';

import '../cancellable_http.dart';
import '../io_client.dart';

class IOSender with Cancellable {
  IOSender(
    this.request,
    this.httpClient,
    this.cancellationToken,
  ) : completer = Completer() {
    _send();
  }

  final BaseRequest request;
  final HttpClient? httpClient;
  final CancellationToken? cancellationToken;
  final Completer<IOStreamedResponse> completer;
  HttpClientRequest? ioRequest;

  Future<IOStreamedResponse> get result => completer.future;

  Future<void> _send() async {
    if (!maybeAttach(cancellationToken)) return;

    if (httpClient == null) {
      return completer.completeError(
        ClientException(
          'HTTP request failed. Client is already closed.',
          request.url,
        ),
        StackTrace.current,
      );
    }

    final stream = request.finalize();

    try {
      // Open the connection
      ioRequest = (await httpClient!.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..contentLength = (request.contentLength ?? -1)
        ..persistentConnection = request.persistentConnection;

      // Cancel the request immediately if the token was cancelled
      if (cancellationToken?.isCancelled ?? false) {
        return cancellationToken?.detach(this);
      }

      // Add the request headers
      request.headers.forEach((name, value) {
        ioRequest!.headers.set(name, value);
      });

      // Send the request body
      final response = await stream.pipe(ioRequest!) as HttpClientResponse;

      // Get the headers from the response
      final responseHeaders = <String, String>{};
      response.headers.forEach((key, values) {
        responseHeaders[key] = values.join(',');
      });

      // Return the response with the response data stream
      completer.complete(
        IOStreamedResponse(
          response.handleError((Object error) {
            final httpException = error as HttpException;
            throw ClientException(httpException.message, httpException.uri);
          }, test: (error) => error is HttpException),
          response.statusCode,
          contentLength:
              response.contentLength == -1 ? null : response.contentLength,
          request: request,
          headers: responseHeaders,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          inner: response,
        ),
      );
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        final exception =
            e is HttpException ? ClientException(e.message, e.uri) : e;
        completer.completeError(exception, stackTrace);
      }
      cancellationToken?.detach(this);
    }
  }

  @override
  void onCancel(Exception cancelException, [StackTrace? trace]) {
    if (!completer.isCompleted) completer.completeError(cancelException);
    ioRequest?.abort(cancelException);
  }
}
