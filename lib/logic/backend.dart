import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_hello_world/logic/selection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'image/image_state.dart';

class Backend {
  // Public vars

  final ValueNotifier<List<MapEntry<int, File>>> galleryImages =
      ValueNotifier([]);

  final Selection selection = Selection();

  Stream<GallerySnackbarMessage> get gallerySnackbarStream =>
      _gallerySnackbarStream.stream;

  // Private vars

  final _sharedFilesSubscription = Completer<StreamSubscription>();

  final _gallerySnackbarStream = StreamController<GallerySnackbarMessage>();

  // Initialization

  Backend() {
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
    __removeImages(Set.of(selection));
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
    __addImages(filtered);
  }

  // ignore: use_setters_to_change_properties
  void _onUpdateGalleryImages(List<MapEntry<int, File>> images) {
    galleryImages.value = images;
  }

  void _onImagesAdded(Set<int> ids) {
    _gallerySnackbarStream.add(
      GalleryImagesAdded(
        ids.length,
        () => __removeImages(ids),
      ),
    );
  }

  void _onImagesRemoved(Set<int> ids) {
    _gallerySnackbarStream.add(
      GalleryImagesRemoved(
        ids.length,
        () => __restoreImages(ids),
      ),
    );
  }

  /// ` Image Store `

  final __imageStore = <ImageState>[];
  final __imagesOrder = <int>[];

  void __addImages(List<File> images) {
    final ids = <int>{};

    images.map((x) => ImageState(x)).forEach(
      (image) {
        final id = __imageStore.length;
        ids.add(id);
        __imageStore.add(image);
      },
    );

    __imagesOrder.insertAll(0, ids);

    _onUpdateGalleryImages(
      __makeGalleryImages(__imageStore, __imagesOrder),
    );

    _onImagesAdded(ids);
  }

  void __removeImages(Set<int> ids) {
    for (final id in ids) {
      __imagesOrder.remove(id);
    }

    _onUpdateGalleryImages(
      __makeGalleryImages(__imageStore, __imagesOrder),
    );

    _onImagesRemoved(ids);
  }

  void __restoreImages(Set<int> ids) {
    __imagesOrder.insertAll(
      0,
      ids.where(
        (x) => x < __imageStore.length && !__imagesOrder.contains(x),
      ),
    );

    _onUpdateGalleryImages(
      __makeGalleryImages(__imageStore, __imagesOrder),
    );

    _onImagesAdded(ids);
  }

  List<MapEntry<int, File>> __makeGalleryImages(
    List<ImageState> store,
    List<int> order,
  ) {
    return order
        .map(
          (id) => MapEntry(id, store[id].file),
        )
        .toList();
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
