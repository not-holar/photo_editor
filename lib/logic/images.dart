import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ImageData {
  File image;

  ImageData(this.image);
}

class ImageDataList with ChangeNotifier {
  ImageDataList() {
    // For sharing images coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      final filtered = value
          ?.where((x) => x.type == SharedMediaType.IMAGE)
          ?.map((x) => File(x.path));
      if (filtered != null) add(filtered);
      // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      final filtered = value
          ?.where((x) => x.type == SharedMediaType.IMAGE)
          ?.map((x) => File(x.path));
      if (filtered != null) add(filtered);
      // print("Shared:" + (value?.map((f) => f.path)?.join(",") ?? ""));
    });
  }

  final List<ImageData> list = [];
  final message = ImageLogicMessage();

  void add(Iterable<File> images) {
    final filtered = images.where((x) => x != null);

    if (filtered.length == 0) return;

    filtered.forEach((image) => list.insert(0, ImageData(image)));

    notifyListeners();
    // scaffold.currentState.showSnackBar(SnackBar(
    //   behavior: SnackBarBehavior.floating,
    //   content: Text('Added ${filtered.length} images'),
    // ));
  }

  void addFromPicker() {
    FilePicker.getMultiFile(type: FileType.image)?.then((x) {
      if (x != null) add(x);
    });
  }
}

class ImageLogicMessage with ChangeNotifier {
  String value;

  void send(String msg) {
    value = msg;
    notifyListeners();
  }
}
