import 'dart:async';
import 'dart:isolate';

// ignore_for_file: always_require_non_null_named_parameters

class Worker {
  final _fromIsolateStream = ReceivePort();

  final _fromIsolateSubscription = Completer<StreamSubscription>();

  final _toIsolateStream = Completer<SendPort>();

  final _isolateInstance = Completer<Isolate>();

  /// Sends an asynchronous [message] through this send port, to its
  /// corresponding `ReceivePort`.
  ///
  /// The content of [message] can be: primitive values (null, num, bool, double,
  /// String), instances of [SendPort], and lists and maps whose elements are any
  /// of these. List and maps are also allowed to be cyclic.
  ///
  /// In the special circumstances when two isolates share the same code and are
  /// running in the same process (e.g. isolates created via [Isolate.spawn]), it
  /// is also possible to send object instances (which would be copied in the
  /// process). This is currently only supported by the dart vm.
  ///
  /// The send happens immediately and doesn't block.  The corresponding receive
  /// port can receive the message as soon as its isolate's event loop is ready
  /// to deliver it, independently of what the sending isolate is doing.

  void Function(dynamic message) send;

  /// Inherited from [Stream].
  ///
  /// Note that [onError] and [cancelOnError] are ignored since a ReceivePort
  /// will never receive an error.
  ///
  /// The [onDone] handler will be called when the stream closes.
  /// The stream closes when [close] is called.

  FutureOr<void> Function(dynamic onData) _userListenFn;

  Future<StreamSubscription<dynamic>> listen(
    void Function(dynamic) onData,
  ) async {
    _userListenFn = onData;
    return _fromIsolateSubscription.future;
  }

  /// Creates a [Worker], which is an Isolate with the given [function] and
  /// takes care of managing the send and receive ports.

  Worker(void Function(ReceivePort, SendPort) function) {
    assert(function != null);

    send = (dynamic message) {
      _toIsolateStream.future.then((x) => x.send(message));
    };

    FutureOr<void> Function(dynamic onData) listenFn;

    listenFn = (dynamic message) {
      if (message is SendPort) {
        final SendPort toIsolateStream = message;
        send = toIsolateStream.send;
        _toIsolateStream.complete(toIsolateStream);
        listenFn = _userListenFn;
      }
    };

    _fromIsolateSubscription.complete(
      _fromIsolateStream.listen((dynamic message) {
        assert(listenFn != null);
        listenFn?.call(message);
      }),
    );

    // _toIsolateStream.future.then((_) => oneTimeSubscription.cancel());

    Isolate.spawn(
      _spawnIsolate,
      _InitialWorkerMessage(
        sendPort: _fromIsolateStream.sendPort,
        function: function,
      ),
    ).then(
      (x) => _isolateInstance.complete(x),
    );
  }

  /// This function runs in the actual Isolate.

  static void _spawnIsolate(_InitialWorkerMessage initialMessage) {
    assert(initialMessage != null);

    final ReceivePort toIsolateStream = ReceivePort();
    // Send it back to the [Worker] instance.
    initialMessage.sendPort.send(toIsolateStream.sendPort);

    initialMessage.function(toIsolateStream, initialMessage.sendPort);
  }

  void dispose() {
    _isolateInstance.future.then((x) => x.kill());
    send = (dynamic _) => null;
  }
}

class _InitialWorkerMessage {
  final SendPort sendPort;
  final void Function(ReceivePort, SendPort) function;

  _InitialWorkerMessage({
    this.sendPort,
    this.function,
  })  : assert(sendPort != null),
        assert(function != null);
}
