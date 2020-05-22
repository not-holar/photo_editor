import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'messages_to_worker.dart';

void main(ReceivePort receivePort, SendPort sendPort) {
  receivePort.listen((dynamic message) {
    assert(message is MessageToWorker);

    if (message is AddImages) {
      print("Worker received images! ${message.images}");
      // message.images;
    }
    // else if (message is Dispose) {
    //   _flutterIsolate.future.then((x) => x?.kill());
    // }
  });
}

Future<void> addFiles(Iterable<File> files) async {
  if (files == null || files.isEmpty) return;

  // TODO
  //
  // imageListBloc.add.add(
  //   files
  //       .where((file) => file != null)
  //       .map((file) => ImageBloc(ImageState(file)))
  //       .toList(),
  // );
}
