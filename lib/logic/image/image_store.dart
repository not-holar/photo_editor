import 'dart:io';

import 'image_state.dart';

class ImageStore {
  final void Function(List<MapEntry<int, File>> images) onUpdated;
  final void Function(Set<int> ids) onAdded;
  final void Function(Set<int> ids) onRemoved;

  final _imageStore = <ImageState>[];
  final _imagesOrder = <int>[];

  ImageStore({
    this.onUpdated,
    this.onAdded,
    this.onRemoved,
  });

  void addImages(List<File> images) {
    final ids = <int>{};

    images.map((x) => ImageState(x)).forEach(
      (image) {
        final id = _imageStore.length;
        ids.add(id);
        _imageStore.add(image);
      },
    );

    _imagesOrder.insertAll(0, ids);

    onUpdated(
      makeGalleryImages(_imageStore, _imagesOrder),
    );

    onAdded(ids);
  }

  void removeImages(Set<int> ids) {
    for (final id in ids) {
      _imagesOrder.remove(id);
    }

    onUpdated(
      makeGalleryImages(_imageStore, _imagesOrder),
    );

    onRemoved(ids);
  }

  void restoreImages(Set<int> ids) {
    _imagesOrder.insertAll(
      0,
      ids.where(
        (x) => x < _imageStore.length && !_imagesOrder.contains(x),
      ),
    );

    onUpdated(
      makeGalleryImages(_imageStore, _imagesOrder),
    );

    onAdded(ids);
  }

  void moveImage(int id, int toIndex) {
    if (toIndex == _imagesOrder.indexOf(id)) {
      return;
    }

    _imagesOrder.remove(id);
    _imagesOrder.insert(toIndex, id);

    onUpdated(
      makeGalleryImages(_imageStore, _imagesOrder),
    );
  }

  List<MapEntry<int, File>> makeGalleryImages(
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
