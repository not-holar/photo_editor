import 'dart:async';

import 'image_state.dart';

class ImageBloc {
  ImageState _state;
  ImageState get state => _state;

  final _deleteInputStream = StreamController<void>();
  StreamSink<void> get delete => _deleteInputStream.sink;

  ImageBloc(ImageState state) {
    _state = state;

    _deleteInputStream.stream.forEach(_delete);
  }

  void _delete(void _) {
    print("Deleted Image with ${_state.toString()}");
  }
}
