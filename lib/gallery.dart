import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

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
  static final imageBackgroundColor = Colors.grey.shade400.withOpacity(.5);

  GalleryGrid({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("""GalleryGrid rebuilt 👷‍♀️""");

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final imageDataList = context.watch<ImageDataList>();

    return CustomScrollView(
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

  final Color backgroundColor;
  final ImageData image;
  final int maxWidth;
  final double pixelRatio;

  const GalleryImage(
    this.image, {
    Key key,
    this.maxWidth = 150,
    this.pixelRatio = 1,
    this.backgroundColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selecting = context.select((ValueNotifier<Set<Key>> x) {
      return x.value.isNotEmpty;
    });
    final selected = context.select((ValueNotifier<Set<Key>> x) {
      return x.value.contains(key);
    });

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
              filterQuality: FilterQuality.high,
              alignment: Alignment.center,
              fit: BoxFit.cover,
              image: ResizeImage.resizeIfNeeded(
                (maxWidth * pixelRatio).round(),
                null,
                FileImage(image.file),
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: () => toggleSelection(context, selected, key),
            onDoubleTap: selecting ? null : () => print("Open image"), // TODO
            enableFeedback: true,
            splashColor: Colors.white10,
          ),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
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

  static void toggleSelection(
    BuildContext context,
    bool selected,
    Key key,
  ) async {
    final v = context.read<ValueNotifier<Set<Key>>>();
    if (selected) {
      v.value = v.value.difference(Set.of([key]));
    } else {
      v.value = v.value.union(Set.of([key]));
    }
  }
}

class GalleryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<Set<Key>>>(
          create: (_) => ValueNotifier(Set()),
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const TopShadow(),
        body: Builder(builder: (context) {
          subscribeToSnackbarStreams(context);
          return GalleryGrid();
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: context.select((ImageDataList x) => x.addFromPicker),
          child: const Icon(Icons.more_vert),
          tooltip: 'Expand Gallery Menu',
        ),
        bottomNavigationBar: SelectionBar(),
      ),
    );
  }
}

class SelectionBar extends StatelessWidget {
  const SelectionBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selecting = context.select((ValueNotifier<Set<Key>> x) {
      return x.value.isNotEmpty;
    });
    return WillPopScope(
      onWillPop: () async {
        if (selecting) {
          context.read<ValueNotifier<Set<Key>>>().value = Set();
        }
        return !selecting;
      },
      child: Visibility(
        visible: selecting,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomAppBarColor.withOpacity(.75),
            border: Border(top: Divider.createBorderSide(context)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    context.read<ValueNotifier<Set<Key>>>().value = Set();
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Builder(builder: (context) {
                      return Text(
                        '${context.watch<ValueNotifier<Set<Key>>>().value.length}',
                        textScaleFactor: 1.3,
                      );
                    }),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    context.read<ValueNotifier<Set<Key>>>().value = Set();
                  },
                ),
              ],
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
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