import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ImageData with ChangeNotifier {
  Key key;
  File file;

  ImageData(this.file) : key = Key(file.hashCode.toString());

  void delete() async {
    // file.parent;
    dispose();
  }

  @override
  String toString() {
    return 'ImageData($file, $key)';
  }
}

class ImageDataList with ChangeNotifier {
  StreamSubscription _intentDataStreamSubscription;

  StreamController<ImageDataListMessage> _imageAddedMessageStreamController;

  StreamController<ImageDataListMessage> _imageRemovedMessageStreamController;
  Stream<ImageDataListMessage> imageAddedMessageStream;

  Stream<ImageDataListMessage> imageRemovedMessageStream;

  final List<ImageData> list = [];

  ImageDataList() {
    _imageAddedMessageStreamController =
        StreamController<ImageDataListMessage>.broadcast();
    _imageRemovedMessageStreamController =
        StreamController<ImageDataListMessage>.broadcast();

    imageAddedMessageStream = _imageAddedMessageStreamController.stream;
    imageRemovedMessageStream = _imageRemovedMessageStreamController.stream;

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        final filtered = value
            ?.where((x) => x.type == SharedMediaType.IMAGE)
            ?.map((x) => File(x.path));

        if (filtered != null) add(filtered);

        // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      final filtered = value
          ?.where((x) => x.type == SharedMediaType.IMAGE)
          ?.map((x) => File(x.path));

      if (filtered != null) add(filtered);

      // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
    });
  }

  void add(final Iterable<File> images) async {
    final converted = images?.whereType<File>()?.map((x) => ImageData(x));

    if (converted?.length == 0) return;

    list.insertAll(0, converted);
    notifyListeners();

    print(list);
    converted.forEach((x) => print(x.file.parent));

    _imageAddedMessageStreamController.add(
      ImageDataListMessage(
        changeAmount: converted.length,
        undoAction: () async {
          converted.forEach((x) {
            list.remove(x);
            x.delete();
          });
          notifyListeners();
          print("""Undone add! ↩""");
        },
        ignoreAction: () async {
          print("""Ignored! 🥳""");
        },
      ),
    );
  }

  void moveItem(int from, int to) async {
    final item = list[from];
    list.insert(to, item);
    list.removeAt(from);

    print(
      """🔀 Moved ${item.key} from $from to $to"""
      """ in list of size ${list.length}""",
    );

    notifyListeners();
  }

  void addFromPicker() async {
    final image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    add([image]);
  }

  @override
  void dispose() {
    _imageAddedMessageStreamController.close();
    _imageRemovedMessageStreamController.close();
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}

class ImageDataListMessage {
  final int changeAmount;

  final void Function() undoAction;
  final void Function() ignoreAction;
  ImageDataListMessage({
    this.changeAmount,
    this.undoAction,
    this.ignoreAction,
  });
}
