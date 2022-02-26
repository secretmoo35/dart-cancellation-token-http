import 'dart:async';
import 'dart:io';

import 'package:cancellation_token/cancellation_token.dart';

import '../cancellable_http.dart';
import '../io_client.dart';

/// Handles sending reguests with cancellation for [IOClient].
class IOSender with Cancellable {
  IOSender(
    BaseRequest request,
    HttpClient? httpClient,
    CancellationToken? cancellationToken,
  ) : completer = Completer() {
    _send(request, httpClient, cancellationToken);
  }

  final Completer<IOStreamedResponse> completer;
  HttpClientRequest? clientRequest;
  HttpClientResponse? clientResponse;
  StreamController<List<int>>? responseStreamController;

  Future<IOStreamedResponse> get result => completer.future;

  /// Sends the request.
  ///
  /// [HttpClientResponse] currently doesn't support aborting with an exception
  /// like [HttpClientRequest] does, so [IOSender] instead creates it's own
  /// stream which response data is passed into. If the request is cancelled
  /// whilst receiving data, the cancellation exception is added to the stream
  /// before closing it, and the socket is detached and destroyed.
  Future<void> _send(
    BaseRequest request,
    HttpClient? httpClient,
    CancellationToken? cancellationToken,
  ) async {
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

    try {
      // Finalise the request and open the connection
      final requestStream = request.finalize();
      clientRequest = (await httpClient.openUrl(request.method, request.url))
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..contentLength = (request.contentLength ?? -1)
        ..persistentConnection = request.persistentConnection;

      // Cancel the request immediately if the token was cancelled
      if (cancellationToken?.isCancelled ?? false) {
        await clientRequest!.close();
        return;
      }

      // Add the request headers
      request.headers.forEach((name, value) {
        clientRequest!.headers.set(name, value);
      });

      // Send the request body
      clientResponse =
          await requestStream.pipe(clientRequest!) as HttpClientResponse;
      clientRequest = null;

      // Get the headers from the response
      final responseHeaders = <String, String>{};
      clientResponse!.headers.forEach((key, values) {
        responseHeaders[key] = values.join(',');
      });

      // Prepare the response stream and pass the client response data into it
      responseStreamController = StreamController();
      clientResponse!.listen(
        (data) => responseStreamController?.add(data),
        onError: (Object error, StackTrace? stackTrace) {
          responseStreamController?.addError(
            _convertHttpException(error),
            stackTrace,
          );
        },
        onDone: () {
          cancellationToken?.detach(this);
          responseStreamController?.close();
          responseStreamController = null;
        },
      );

      // Return the response with the response stream
      completer.complete(
        IOStreamedResponse(
          responseStreamController!.stream,
          clientResponse!.statusCode,
          contentLength: clientResponse!.contentLength == -1
              ? null
              : clientResponse!.contentLength,
          request: request,
          headers: responseHeaders,
          isRedirect: clientResponse!.isRedirect,
          persistentConnection: clientResponse!.persistentConnection,
          reasonPhrase: clientResponse!.reasonPhrase,
          inner: clientResponse,
        ),
      );
    } catch (e, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(_convertHttpException(e), stackTrace);
      }
      cancellationToken?.detach(this);
    }
  }

  @override
  void onCancel(Exception cancelException, [StackTrace? trace]) {
    if (!completer.isCompleted) completer.completeError(cancelException, trace);
    // Add the cancellation exception and close the response stream if it's
    // active
    responseStreamController
      ?..addError(cancelException, trace)
      ..close();
    responseStreamController = null;
    // Abort the HTTP request if cancelled whilst sending the request
    clientRequest?.abort(cancelException, trace);
    // Detatch and destroy the socket to close the connection if cancelled
    // whilst receiving the response body
    clientResponse?.detachSocket().then((value) => value.destroy());
  }

  Object _convertHttpException(Object e) =>
      e is HttpException ? ClientException(e.message, e.uri) : e;
}
