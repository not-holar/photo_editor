import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

import '../../basic_widgets/circular_check_box.dart';
import '../../logic/images.dart';

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<Set<ImageData>>>(
          create: (_) => ValueNotifier(<ImageData>{}),
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const TopShadow(),
        body: Provider<void>(
          create: subscribeToSnackbarStreams,
          lazy: false,
          child: const GalleryGrid(),
        ),
        floatingActionButton: FloatingActionButton(
          // TODO: open menu with gallery and camera (Use animations lib)
          onPressed: context
              .select<ImageDataList, void Function()>((x) => x.addFromPicker),
          tooltip: 'Expand Gallery Menu',
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: const SelectionBar(),
      ),
    );
  }
}

class GalleryGrid extends StatelessWidget {
  static final Color _imageBackgroundColor =
      Colors.grey.shade400.withOpacity(.5);

  const GalleryGrid({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("""GalleryGrid rebuilt 👷‍♀️""");

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverSafeArea(
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 44, 4, 100),
            sliver: Builder(builder: (context) {
              final imageDataList = context.watch<ImageDataList>();
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => GalleryImage(
                    imageDataList.list[index],
                    maxWidth: 150,
                    pixelRatio: devicePixelRatio,
                    backgroundColor: _imageBackgroundColor,
                  ),
                  childCount: imageDataList.list.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  maxCrossAxisExtent: 150,
                ),
              );
            }),
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
    this.maxWidth = 50,
    this.pixelRatio = 1,
    this.backgroundColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selecting = context.select<ValueNotifier<Set<ImageData>>, bool>(
      (x) => x.value.isNotEmpty,
    );
    final selected = context.select<ValueNotifier<Set<ImageData>>, bool>(
      (x) => x.value.contains(image),
    );

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
            onTap: () => toggleSelection(context, image, wasSelected: selected),
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
                gradient: LinearGradient(
                  colors: [Colors.black26, Colors.black12],
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

  static Future<void> toggleSelection(
    BuildContext context,
    ImageData image, {
    bool wasSelected,
  }) async {
    final v = context.read<ValueNotifier<Set<ImageData>>>();
    if (wasSelected) {
      v.value = v.value.difference({image});
    } else {
      v.value = v.value.union({image});
    }
  }
}

class SelectionBar extends StatelessWidget {
  const SelectionBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selecting = context
        .select<ValueNotifier<Set<ImageData>>, bool>((x) => x.value.isNotEmpty);
    return WillPopScope(
      onWillPop: () async {
        if (selecting) {
          context.read<ValueNotifier<Set<ImageData>>>().value = {};
        }
        return !selecting;
      },
      child: Visibility(
        visible: selecting,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: Divider.createBorderSide(context)),
          ),
          child: Material(
            color: Theme.of(context).bottomAppBarColor.withOpacity(.75),
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 24, 5),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      context.read<ValueNotifier<Set<ImageData>>>().value = {};
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Builder(builder: (context) {
                        return Text(
                          context
                              .select<ValueNotifier<Set<ImageData>>, int>(
                                (x) => x.value.length,
                              )
                              .toString(),
                          textScaleFactor: 1.1,
                        );
                      }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      context.read<ImageDataList>().remove(
                          context.read<ValueNotifier<Set<ImageData>>>().value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopShadow extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size(0, 0);

  const TopShadow() : super();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _builder);

  Widget _builder(BuildContext context, BoxConstraints constraints) {
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

void subscribeToSnackbarStreams(BuildContext context) {
  final showSnackBar = Scaffold.of(context).showSnackBar;
  final imageDataList = context.read<ImageDataList>();

  print("""Stream Subscription 🌊""");

  // Added Stream
  imageDataList.imageAddedMessageStream.forEach(
    (message) async {
      final reason = await showSnackBar(SnackBar(
        // behavior: SnackBarBehavior.floating,

        // TODO: make correct plurals
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
  imageDataList.imageRemovedMessageStream.forEach(
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
