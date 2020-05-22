import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_hello_world/logic/selection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'messages_from_worker.dart';
import 'messages_to_worker.dart';
import 'worker.dart';
import 'worker_main.dart' as worker_main show main;

class Backend {
  // Public vars

  final ValueNotifier<List<MapEntry<int, File>>> galleryImages =
      ValueNotifier([]);

  final Selection selection = Selection();

  Stream<GallerySnackbarMessage> get gallerySnackbarStream =>
      _gallerySnackbarStream.stream;

  // Private vars

  final _worker = Worker(worker_main.main);

  final _workerStreamSubscription = Completer<StreamSubscription>();
  final _sharedFilesSubscription = Completer<StreamSubscription>();

  final _gallerySnackbarStream = StreamController<GallerySnackbarMessage>();

  // Initialization

  Backend() {
    _worker.listen(_listener).then(_workerStreamSubscription.complete);

    try {
      List<File> processShared(List<SharedMediaFile> shared) => shared
          ?.where((x) => x.type == SharedMediaType.IMAGE)
          ?.map((x) => File(x.path))
          ?.toList();

      _sharedFilesSubscription.complete(
        ReceiveSharingIntent.getMediaStream().listen(
          (list) => _addFiles(processShared(list)),
          onError: (dynamic err) => print("getIntentDataStream error: $err"),
        ),
      );

      ReceiveSharingIntent.getInitialMedia()
          .then((list) => _addFiles(processShared(list)));
      //
    } catch (_) {}

    try {
      ImagePicker.retrieveLostData().then((x) {
        if (x != null && x.file != null) _addFiles([x.file]);
      });
    } catch (_) {}
  }

  // Backend Public Methods

  void addFromPicker() {
    try {
      ImagePicker.pickImage(
        source: ImageSource.gallery,
      ).then((file) => _addFiles([file]));
    } catch (_) {}
  }

  void deleteSelected() {
    _worker.send(RemoveImages(Set.of(selection)));
  }

  void dispose() {
    _worker.dispose();
    selection.dispose();
    _workerStreamSubscription.future.then((x) => x.cancel());
    _sharedFilesSubscription.future.then((x) => x.cancel());
    _gallerySnackbarStream.close();
  }

  // Backend Private Methods

  void _listener(dynamic message) {
    assert(message is MessageFromWorker);
    print("Backend received: $message");

    if (message is UpdateGalleryImages) {
      galleryImages.value = message.images
          .map(
            (x) => MapEntry(x.key, File(x.value)),
          )
          .toList();
    } else if (message is ImagesAdded) {
      _gallerySnackbarStream.add(
        GalleryImagesAdded(
          message.ids.length,
          () => _worker.send(RemoveImages(message.ids)),
        ),
      );
    } else if (message is ImagesRemoved) {
      _gallerySnackbarStream.add(
        GalleryImagesRemoved(
          message.ids.length,
          () => _worker.send(RestoreImages(message.ids)),
        ),
      );
    }
    //
  }

  void _addFiles(List<File> files) {
    final filtered = files?.where((x) => x != null)?.toList();
    if (filtered == null || filtered.isEmpty) return;
    _worker.send(AddImages(filtered));
  }
}

/// Message to `Gallery Snackbar`

class GallerySnackbarMessage {}

class GalleryImagesAdded extends GallerySnackbarMessage {
  final int amount;
  final void Function() undo;

  GalleryImagesAdded(this.amount, this.undo)
      : assert(amount != null),
        assert(undo != null);
}

class GalleryImagesRemoved extends GallerySnackbarMessage {
  final int amount;
  final void Function() undo;

  GalleryImagesRemoved(this.amount, this.undo)
      : assert(amount != null),
        assert(undo != null);
}
