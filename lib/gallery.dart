import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

class _Image {
  File image;

  _Image(this.image);
}

List<_Image> _images = [];

Future getImage() async {
  var image = await ImagePicker.pickImage(source: ImageSource.gallery);
  if (image != null) _images.insert(0, _Image(image));
}

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GridView.builder(
            itemCount: _images.length,
            padding: EdgeInsets.fromLTRB(
                4, 44 + MediaQuery.of(context).viewPadding.top, 4, 100),
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (BuildContext context, int index) {
              return GalleryImage(_images[index]);
            },
          ),
          TopShadow(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Add a photo',
        child: Icon(Icons.add),
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  GalleryImage(this.image);

  final _Image image;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Image.file(
        image.image,
        filterQuality: FilterQuality.high,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio / 3).round(),
      ),
    );
  }
}

class TopShadow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.transparent,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withOpacity(
                WidgetsBinding.instance.window.platformBrightness ==
                        Brightness.light
                    ? .9
                    : .5),
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      height: MediaQuery.of(context).viewPadding.top,
    );
  }
}
