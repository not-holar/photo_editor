import 'dart:io';

abstract class MessageToWorker {}

class Dispose extends MessageToWorker {}

class AddImages extends MessageToWorker {
  List<File> images;

  AddImages(this.images) : assert(images != null);
}
