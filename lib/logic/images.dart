import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ImageData extends ChangeNotifier {
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

class ImageDataList extends ChangeNotifier {
  StreamSubscription _intentDataStreamSubscription;

  StreamController<ImageDataListMessage> _imageAddedMessageStreamController;

  StreamController<ImageDataListMessage> _imageRemovedMessageStreamController;
  Stream<ImageDataListMessage> imageAddedMessageStream;

  Stream<ImageDataListMessage> imageRemovedMessageStream;

  final List<ImageData> list = [];

  bool _indexMapIsRelevant = true;
  Map<ImageData, int> _indexMap = {};
  Map<ImageData, int> get indexMap {
    if (_indexMapIsRelevant) {
      print("""There was a point in relevancy 😳""");
      return _indexMap;
    } else {
      _indexMap = list.asMap().map((a, b) => MapEntry(b, a));
      _indexMapIsRelevant = true;
      return _indexMap;
    }
  }

  ImageDataList() {
    _imageAddedMessageStreamController =
        StreamController<ImageDataListMessage>();
    _imageRemovedMessageStreamController =
        StreamController<ImageDataListMessage>();

    imageAddedMessageStream = _imageAddedMessageStreamController.stream;
    imageRemovedMessageStream = _imageRemovedMessageStreamController.stream;

    // For sharing images coming from outside
    // the app while the app is in memory

    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen(
      (value) {
        final filtered = value
            ?.where((x) => x.type == SharedMediaType.IMAGE)
            ?.map((x) => File(x.path));

        if (filtered != null) convert(filtered).then(add);

        // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((value) {
      final filtered = value
          ?.where((x) => x.type == SharedMediaType.IMAGE)
          ?.map((x) => File(x.path));

      if (filtered != null) convert(filtered).then(add);

      // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
    });

    Future(() {
      ImagePicker.retrieveLostData().then((x) {
        return convert([x.file]);
      }).then(add);
    }).catchError((e) {
      print("Restore error: ${e.error}");
    });
  }

  Future<List<ImageData>> convert(Iterable<File> files) async {
    return files?.whereType<File>()?.map((x) => ImageData(x))?.toList();
  }

  Future<bool> add(final Iterable<ImageData> images) async {
    if (images?.length == 0) return false;

    list.insertAll(0, images);
    notifyListeners();

    _imageAddedMessageStreamController.add(
      ImageDataListMessage(
        changeAmount: images.length,
        undoAction: () async {
          await remove(images);
          print("""Undone add! ↩""");
        },
      ),
    );

    return true;
  }

  Future<bool> remove(final Iterable<ImageData> images) async {
    if (images?.length == 0) return false;

    for (final x in images) {
      list.remove(x);
    }
    notifyListeners();

    _imageRemovedMessageStreamController.add(
      ImageDataListMessage(
        changeAmount: images.length,
        undoAction: () async {
          await add(images);
          print("""Undone remove! ↩""");
        },
        ignoreAction: () async {
          for (final x in images) {
            x.delete();
          }
          print("""Comitted deletetion 🥳""");
        },
      ),
    );

    return true;
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

    convert([image]).then(add);
  }

  @override
  void notifyListeners() {
    _indexMapIsRelevant = false;
    super.notifyListeners();
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
