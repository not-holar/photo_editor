import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';

import 'logic/images.dart';
import 'primitive/circular_check_box.dart';

void subscribeToSnackbarStreams(BuildContext context) {
  final showSnackBar = Scaffold.of(context).showSnackBar;

  // Added Stream
  context.select((ImageDataList x) => x.imageAddedMessageStream).forEach(
    (message) async {
      final reason = await showSnackBar(SnackBar(
        // behavior: SnackBarBehavior.floating,
        content: Text('Added ${message.changeAmount} images'),
        action: message.undoAction == null
            ? null
            : SnackBarAction(
                onPressed: message.undoAction,
                label: "UNDO",
              ),
      )).closed;

      if (reason != SnackBarClosedReason.action) {
        message?.ignoreAction?.call();
      }
    },
  );

  // Removed Stream
  context.select((ImageDataList x) => x.imageRemovedMessageStream).forEach(
    (message) async {
      final reason = await showSnackBar(SnackBar(
        // behavior: SnackBarBehavior.floating,
        content: Text(
          'Removed ${message.changeAmount} images',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        action: message.undoAction == null
            ? null
            : SnackBarAction(
                onPressed: message.undoAction,
                label: "UNDO",
                textColor: Colors.white,
              ),
        backgroundColor: Colors.redAccent,
      )).closed;

      if (reason != SnackBarClosedReason.action) {
        message?.ignoreAction?.call();
      }
    },
  );
}

class GalleryGrid extends StatelessWidget {
  GalleryGrid({Key key}) : super(key: key);

  static final imageBackgroundColor = Colors.grey.shade400.withOpacity(.5);

  @override
  Widget build(BuildContext context) {
    final gridController = context.select(
      (DragSelectGridViewController x) => x,
    );
    if (gridController.selection.amount != 0) gridController.clear();

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final imageDataList = context.watch<ImageDataList>();

    // return DragSelectGridView(
    //   gridController: gridController,
    //   itemCount: imageDataList.list.length,
    //   padding: EdgeInsets.only(
    //     top: 44 + MediaQuery.of(context).viewPadding.top,
    //     bottom: 50,
    //     left: 4,
    //     right: 4,
    //   ),
    //   physics: const BouncingScrollPhysics(),
    //   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    //     mainAxisSpacing: 4,
    //     crossAxisSpacing: 4,
    //     maxCrossAxisExtent: 150,
    //   ),
    //   itemBuilder: (_, index, selected) => GalleryImage(
    //     imageDataList.list[index],
    //     key: imageDataList.list[index].key,
    //     maxWidth: 150,
    //     selected: selected,
    //     selecting: gridController.selection.isSelecting,
    //     pixelRatio: devicePixelRatio,
    //     backgroundColor: imageBackgroundColor,
    //   ),
    // );

    final scrollController = ScrollController();

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverSafeArea(
          sliver: SliverPadding(
            padding: EdgeInsets.fromLTRB(4, 44, 4, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => GalleryImage(
                  imageDataList.list[index],
                  key: imageDataList.list[index].key,
                  maxWidth: 150,
                  selected: false,
                  selecting: gridController.selection.isSelecting,
                  pixelRatio: devicePixelRatio,
                  backgroundColor: imageBackgroundColor,
                ),
                childCount: imageDataList.list.length,
                findChildIndexCallback: (key) {
                  return imageDataList.list.indexWhere((x) {
                    return x.key == key;
                  });
                },
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                maxCrossAxisExtent: 150,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GalleryImage extends StatelessWidget {
  static const curve = Curves.fastOutSlowIn;

  static const duration = Duration(milliseconds: 250);
  final int maxWidth;
  final ImageData image;
  final bool selected;
  final bool selecting;
  final double pixelRatio;
  final Color backgroundColor;

  const GalleryImage(
    this.image, {
    Key key,
    this.maxWidth = 150,
    this.selected = false,
    this.selecting = false,
    this.pixelRatio = 1,
    this.backgroundColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: backgroundColor,
          child: AnimatedPadding(
            padding: selected ? const EdgeInsets.all(15) : EdgeInsets.zero,
            duration: duration,
            curve: curve,
            child: Image(
              image: ResizeImage.resizeIfNeeded(
                (maxWidth * pixelRatio).round(),
                null,
                FileImage(image.file),
              ),
              filterQuality: FilterQuality.high,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: selecting ? 1.0 : 0.0,
          duration: duration,
          curve: curve,
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

class ReorderableGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final imageDataList = context.watch<ImageDataList>();

    return ReorderableListView(
      padding: EdgeInsets.only(
        top: 44 + query.viewPadding.top,
        bottom: 50,
        left: 4,
        right: 4,
      ),
      onReorder: (from, to) => imageDataList.moveItem(from, to),
      children: [
        for (final image in imageDataList.list)
          Card(
            key: image.key,
            child: ListTile(
              leading: AspectRatio(
                aspectRatio: 1,
                child: Image.file(
                  image.file,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  cacheWidth: (100 * query.devicePixelRatio).round(),
                ),
              ),
              title: Text('Image ${image.key}'),
              // The child of a Handle can initialize a drag/reorder.
              // This could for example be an Icon or the whole item itself. You can
              // use the delay parameter to specify the duration for how long a pointer
              // must press the child, until it can be dragged.
              trailing: const Icon(
                Icons.drag_handle,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DragSelectGridViewController>(
          create: (_) => DragSelectGridViewController(),
        ),
        ChangeNotifierProvider<ValueNotifier<int>>(
          create: (_) => ValueNotifier(0),
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const TopShadow(),
        body: Builder(builder: (context) {
          subscribeToSnackbarStreams(context);

          return Builder(builder: (context) {
            return IndexedStack(
              index: context.watch<ValueNotifier<int>>().value,
              sizing: StackFit.expand,
              children: [
                GalleryGrid(),
                ReorderableGallery(),
              ],
            );
          });
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: context.select((ImageDataList x) => x.addFromPicker),
          child: const Icon(Icons.more_vert),
          tooltip: 'Expand Gallery Menu',
        ),
      ),
    );
  }
}

class TopShadow extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const TopShadow()
      : preferredSize = const Size(0, 0),
        super();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: builder);

  Widget builder(context, constraints) {
    return Visibility(
      visible: constraints.maxHeight != 0,
      child: IgnorePointer(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Theme.of(context).brightness,
            statusBarIconBrightness: ThemeData.estimateBrightnessForColor(
              Theme.of(context).colorScheme.onBackground,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.background.withOpacity(.9),
                  Theme.of(context).colorScheme.background.withOpacity(0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
