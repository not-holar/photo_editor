import 'dart:io';

class ImageState {
  final File _source;

  ImageState(this._source);

  File get file => _source;
  int get key => _source.hashCode;

  @override
  String toString() {
    return 'ImageState($file, $key)';
  }
}
