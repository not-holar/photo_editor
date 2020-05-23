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
      final ids = <int>{};

      message.images.map((x) => ImageState(x)).forEach(
        (image) {
          final id = imageStore.length;
          ids.add(id);
          imageStore.add(image);
        },
      );

      imagesOrder.insertAll(0, ids);

      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));

      sendPort.send(ImagesAdded(ids));

      //
    } else if (message is RemoveImages) {
      for (final id in message.ids) {
        imagesOrder.remove(id);
      }

      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));

      sendPort.send(ImagesRemoved(message.ids));

      //
    } else if (message is RestoreImages) {
      imagesOrder.insertAll(
        0,
        message.ids.where((x) => x < imageStore.length),
      );

      sendPort.send(UpdateGalleryImages(
        galleryImages(imageStore, imagesOrder),
      ));

      sendPort.send(ImagesRemoved(message.ids));

      //
    }
  });
}

List<MapEntry<int, String>> galleryImages(
  List<ImageState> store,
  List<int> order,
) {
  return order
      .map(
        (id) => MapEntry(id, store[id].file.path),
      )
      .toList();
}
