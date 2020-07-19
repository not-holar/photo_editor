import 'package:flutter/material.dart';

import 'package:flutter_stream_listener/flutter_stream_listener.dart';
import 'package:provider/provider.dart';

import '../../logic/backend.dart';

class SnackbarListener extends StatelessWidget {
  final Widget child;

  const SnackbarListener({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamListener<GallerySnackbarMessage>(
      stream: context.watch<Backend>().gallerySnackbarStream,
      onData: (message) => onData(message, context),
      child: child,
    );
  }

  void onData(GallerySnackbarMessage message, BuildContext context) {
    if (message is GalleryImagesAdded) {
      Scaffold.of(context).showSnackBar(SnackBar(
        // TODO: make correct plurals
        content: Text('Added ${message.amount} images'),
        action: SnackBarAction(
          onPressed: message.undo,
          label: "UNDO",
        ),
      ));
    } else if (message is GalleryImagesRemoved) {
      Scaffold.of(context).showSnackBar(SnackBar(
        // behavior: SnackBarBehavior.floating,
        content: Text(
          'Removed ${message.amount} images',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        action: SnackBarAction(
          onPressed: message.undo,
          label: "UNDO",
          textColor: Colors.white,
        ),
        backgroundColor: Colors.redAccent,
      ));
    }
  }
}
