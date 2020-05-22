import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'messages_to_worker.dart';
import 'worker.dart';
import 'worker_main.dart' as worker_main show main;

class Backend {
  final _worker = Worker(worker_main.main);

  final ValueNotifier<List<File>> galleryImages = ValueNotifier([]);

  // Initialization

  Backend() {
    try {
      List<File> processShared(List<SharedMediaFile> shared) {
        if (shared == null || shared.isEmpty) return null;

        return shared
            ?.where((x) => x.type == SharedMediaType.IMAGE)
            ?.map((x) => File(x.path))
            ?.toList();
      }

      ReceiveSharingIntent.getMediaStream().listen(
        (list) => _addFiles(processShared(list)),
        onError: (dynamic err) => print("getIntentDataStream error: $err"),
      );
      ReceiveSharingIntent.getInitialMedia().then(
        (list) => _addFiles(processShared(list)),
      );
    } catch (_) {}

    try {
      ImagePicker.retrieveLostData().then((x) {
        if (x != null && x.file != null) _addFiles([x.file]);
      });
    } catch (_) {}
  }

  // Backend Public Methods

  void addFromPicker() {
    ImagePicker.pickImage(
      source: ImageSource.gallery,
    ).then((file) => _addFiles([file]));
  }

  void deleteSelection() {
    // TODO
  }

  void dispose() {
    _worker.dispose();
  }

  // Backend Private Methods

  void _addFiles(List<File> files) {
    final filtered = files?.where((x) => x != null)?.toList();
    if (filtered == null || filtered.isEmpty) return;
    _worker.send(AddImages(filtered));
  }
}
