import 'dart:io';
import 'dart:isolate';

import 'image/image_state.dart';

import 'messages_from_worker.dart';
import 'messages_to_worker.dart';

void main(ReceivePort receivePort, SendPort sendPort) {
  final imageStore = <ImageState>[];
  final imagesOrder = <int>[];

  receivePort.listen((dynamic message) {
    assert(message is MessageToWorker);
    print("Worker received: $message");

    if (message is AddImages) {
      message.images.map((x) => ImageState(x)).forEach(
        (image) {
          final id = imageStore.length;
          imagesOrder.insert(0, id);
          imageStore.add(image);
        },
      );
      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));
    } else if (message is RemoveImages) {
      for (final id in message.ids) {
        imagesOrder.remove(id);
      }
      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));
    } else if (message is RestoreImages) {
      imagesOrder.insertAll(
        0,
        message.ids.where((x) => x < imageStore.length),
      );
      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));
    }
  });
}

List<MapEntry<int, File>> galleryImages(
  List<ImageState> store,
  List<int> order,
) {
  return order
      .map(
        (id) => MapEntry(id, store[id].file),
      )
      .toList();
}
