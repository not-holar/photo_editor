import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_hello_world/logic/selection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'image/image_store.dart';

class Backend {
  // Public vars

  final ValueNotifier<List<MapEntry<int, File>>> galleryImages =
      ValueNotifier([]);

  final Selection selection = Selection();

  ImageStore _imageStore;

  Stream<GallerySnackbarMessage> get gallerySnackbarStream =>
      _gallerySnackbarStream.stream;

  // Private vars

  final _sharedFilesSubscription = Completer<StreamSubscription>();

  final _gallerySnackbarStream = StreamController<GallerySnackbarMessage>();

  // Initialization

  Backend() {
    _imageStore = ImageStore(
      onUpdated: _onImagesUpdated,
      onAdded: _onImagesAdded,
      onRemoved: _onImagesRemoved,
    );

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

  Future<bool> addFromPicker() async {
    final file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (file != null) {
      _addFiles([file]);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> addFromCamera() async {
    final file = await ImagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (file != null) {
      _addFiles([file]);
      return true;
    } else {
      return false;
    }
  }

  void deleteSelected() {
    _imageStore.removeImages(Set.of(selection));
    selection.clear();
  }

  void dispose() {
    selection.dispose();
    _sharedFilesSubscription.future.then((x) => x.cancel());
    _gallerySnackbarStream.close();
  }

  // Backend Private Methods

  void _addFiles(List<File> files) {
    final filtered = files?.where((x) => x != null)?.toList();
    if (filtered == null || filtered.isEmpty) return;
    _imageStore.addImages(filtered);
  }

  // ignore: use_setters_to_change_properties
  void _onImagesUpdated(List<MapEntry<int, File>> images) {
    galleryImages.value = images;
  }

  void _onImagesAdded(Set<int> ids) {
    _gallerySnackbarStream.add(
      GalleryImagesAdded(
        ids.length,
        () => _imageStore.removeImages(ids),
      ),
    );
  }

  void _onImagesRemoved(Set<int> ids) {
    _gallerySnackbarStream.add(
      GalleryImagesRemoved(
        ids.length,
        () => _imageStore.restoreImages(ids),
      ),
    );
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
