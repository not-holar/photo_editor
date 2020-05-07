import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class _Image {
  String text;

  _Image(String text) {
    this.text = text;
  }
}

List<_Image> _images = List.generate(
  33,
  (index) => _Image('Image $index'),
);

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
        onPressed: () {},
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
      child: Center(
        child: Text(
          image.text,
          style: Theme.of(context).textTheme.caption,
        ),
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
