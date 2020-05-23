import 'dart:io';

/// Message `TO` worker

abstract class MessageToWorker {}

// class Dispose extends MessageToWorker {}

class AddImages extends MessageToWorker {
  final List<File> images;

  AddImages(this.images) : assert(images != null);
}

class RemoveImages extends MessageToWorker {
  final Set<int> ids;

  RemoveImages(this.ids) : assert(ids != null);
}

class RestoreImages extends MessageToWorker {
  final Set<int> ids;

  RestoreImages(this.ids) : assert(ids != null);
}
