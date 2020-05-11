import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';

import 'primitive/circular_check_box.dart';
import 'logic/images.dart';

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        Consumer<ImageDataList>(
          builder: (context, images, _) {
            final gridController = DragSelectGridViewController();

            gridController.addListener(
              () => print(gridController.selection),
            );

            return DragSelectGridView(
              gridController: gridController,
              itemCount: images.list.length,
              padding: EdgeInsets.fromLTRB(
                  4, 44 + MediaQuery.of(context).viewPadding.top, 4, 50),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                maxCrossAxisExtent: 150,
              ),
              itemBuilder: (_, index, selected) => GalleryImage(
                images.list[index],
                maxWidth: 150,
                selected: selected,
                selecting: gridController.selection.isSelecting,
              ),
            );
          },
        ),
        const TopShadow(),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.more_vert),
        tooltip: 'Expand Gallery Menu',
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  GalleryImage(
    this.image, {
    this.maxWidth = 150,
    this.selected = false,
    this.selecting = false,
  });

  final int maxWidth;
  final ImageData image;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.grey.shade400.withOpacity(.5),
          child: AnimatedPadding(
            padding: selected ? const EdgeInsets.all(15) : EdgeInsets.zero,
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            child: Image(
              image: ResizeImage.resizeIfNeeded(
                (maxWidth * MediaQuery.of(context).devicePixelRatio).round(),
                null,
                FileImage(image.image),
              ),
              filterQuality: FilterQuality.high,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        Visibility(
          visible: selecting,
          child: Container(
            alignment: Alignment.bottomLeft,
            decoration: const BoxDecoration(
              gradient: const LinearGradient(
                colors: const [Colors.black26, Colors.black12],
              ),
            ),
            child: IgnorePointer(
              child: CircularCheckBox(
                checkColor: Colors.black,
                activeColor: Colors.white,
                inactiveColor: Colors.white54,
                value: selected,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TopShadow extends StatelessWidget {
  const TopShadow() : super();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Theme.of(context).brightness,
        statusBarIconBrightness: ThemeData.estimateBrightnessForColor(
          Theme.of(context).colorScheme.onBackground,
        ),
      ),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.background.withOpacity(.9),
                Theme.of(context).colorScheme.background.withOpacity(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          height: MediaQuery.of(context).viewPadding.top + 5,
        ),
      ),
    );
  }
}
