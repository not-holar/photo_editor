import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rxdart/rxdart.dart';

import 'image/image_bloc.dart';
import 'image/image_state.dart';
import 'image_list/image_list_bloc.dart';
import 'image_list/image_list_state.dart';

class AppBloc {
  final _imageListBloc = ImageListBloc();
  ValueStream<ImageListState> get imageListStream => _imageListBloc.stateStream;
  Stream<ImageListMessage> get imagesAddedMessageStream =>
      _imageListBloc.imageAddedMessageStream;
  Stream<ImageListMessage> get imagesRemovedMessageStream =>
      _imageListBloc.imageRemovedMessageStream;

  final _addFromPickerInputStream = StreamController<void>();
  StreamSink<void> get addFromPicker => _addFromPickerInputStream.sink;

  AppBloc() {
    // For sharing images coming from outside
    // the app while the app is in memory
    ReceiveSharingIntent.getMediaStream().listen(
      _processShared,
      onError: (dynamic err) {
        print("getIntentDataStream error: $err");
      },
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(_processShared);

    try {
      ImagePicker.retrieveLostData()
          .then((x) => [ImageBloc(ImageState(x.file))])
          .then((value) => null);
    } catch (e) {
      print("Restore error: ${e.error}");
    }

    _addFromPickerInputStream.stream.forEach(_addFromPicker);
  }

  Future<void> _addFromPicker(void _) async {
    final image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    _imageListBloc.add.add(
      [ImageBloc(ImageState(image))],
    );
  }

  void _processShared(List<SharedMediaFile> shared) {
    final processed = shared
        ?.where((x) => x.type == SharedMediaType.IMAGE)
        ?.map((x) => File(x.path))
        ?.map((x) => ImageBloc(ImageState(x)));

    if (processed == null || processed.isEmpty) return;

    _imageListBloc.add.add(processed.toList());
  }
}
