import 'package:circular_check_box/circular_check_box.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'logic/images.dart';

class GalleryPage extends StatelessWidget {
  static const double pillHeight = 50;
  static const double bottomSheetPeekHeight = pillHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Consumer<ImageDataList>(
            builder: (_, images, __) {
              final gridController = DragSelectGridViewController();

              gridController.addListener(
                () => print(gridController.selection),
              );

              return DragSelectGridView(
                gridController: gridController,
                itemCount: images.list.length,
                padding: EdgeInsets.fromLTRB(
                  4,
                  44 + MediaQuery.of(context).viewPadding.top,
                  4,
                  50 + bottomSheetPeekHeight,
                ),
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
          Builder(
            builder: (context) {
              final images = Provider.of<ImageDataList>(context, listen: false);

              const initialHeight = bottomSheetPeekHeight;
              const childrenHeight = 65.0 * 1;
              const padding = const EdgeInsets.fromLTRB(0, 0, 0, 20);
              final contextHeight = MediaQuery.of(context).size.height;
              final minHeight = (initialHeight / contextHeight).clamp(0, .5);
              final maxHeight =
                  ((initialHeight + childrenHeight + padding.vertical) /
                          contextHeight)
                      .clamp(minHeight, .9);

              return DraggableScrollableSheet(
                minChildSize: minHeight,
                initialChildSize: minHeight,
                maxChildSize: maxHeight,
                builder: (context, scrollController) {
                  return Material(
                    borderRadius: const BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    elevation: 10,
                    child: ListView(
                      shrinkWrap: false,
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        const Pill(
                          height: pillHeight,
                        ),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.only(left: 20, right: 10),
                          leading: const Icon(Icons.add),
                          title: const Text("Add images"),
                          onTap: images.addFromPicker,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
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
      children: [
        Container(
          color: Theme.of(context).dividerColor,
          constraints: BoxConstraints.expand(),
          child: AnimatedPadding(
            padding: EdgeInsets.all(selected ? 15 : 0),
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
          child: IgnorePointer(
            child: CircularCheckBox(
              value: selected,
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    Key key,
    this.height,
  }) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .1,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.2),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
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
