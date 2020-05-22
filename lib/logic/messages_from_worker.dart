import 'dart:io';

/// Message `FROM` worker

abstract class MessageFromWorker {}

class UpdateGalleryImages extends MessageFromWorker {
  List<MapEntry<int, File>> images;

  UpdateGalleryImages(this.images) : assert(images != null);
}

class ImagesRemoved extends MessageFromWorker {
  final Set<int> ids;

  ImagesRemoved(this.ids) : assert(ids != null);
}

class ImagesAdded extends MessageFromWorker {
  final Set<int> ids;

  ImagesAdded(this.ids) : assert(ids != null);
}
