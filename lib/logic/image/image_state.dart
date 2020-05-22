import 'dart:io';

class ImageState {
  final File _source;

  ImageState(this._source);

  File get file => _source;

  @override
  String toString() {
    return 'ImageState($file)';
  }
}
