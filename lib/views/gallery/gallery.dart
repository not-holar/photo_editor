import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hello_world/logic/selection.dart';
import 'package:flutter_stream_listener/flutter_stream_listener.dart';

import 'package:provider/provider.dart';

import 'package:flutter_hello_world/basic_widgets/circular_check_box.dart';
import 'package:flutter_hello_world/logic/backend.dart';

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<List<MapEntry<int, File>>>>(
          create: (_) => backend.galleryImages,
        ),
        ChangeNotifierProvider<Selection>(
          create: (_) => backend.selection,
        ),
      ],
      child: Scaffold(
        appBar: const TopShadow(),
        extendBodyBehindAppBar: true,
        body: const SnackbarListener(
          child: GalleryGrid(),
        ),
        floatingActionButton: FloatingActionButton(
          // TODO: open menu with gallery and camera (Use animations lib)
          onPressed: backend.addFromPicker,
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

    return Consumer<ValueNotifier<List<MapEntry<int, File>>>>(
      builder: (context, list, _) => Consumer<Selection>(
        builder: (_, selection, __) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(4, 44, 4, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    maxCrossAxisExtent: 150,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => GalleryImage(
                      maxWidth: 150,
                      pixelRatio: devicePixelRatio,
                      backgroundColor: _imageBackgroundColor,
                      image: list.value[index].value,
                      toggleSelection: () =>
                          selection.toggle(list.value[index].key),
                      selecting: selection.selecting,
                      selected: selection.has(list.value[index].key),
                    ),
                    childCount: list.value.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  static const curve = Curves.fastOutSlowIn;
  static const duration = Duration(milliseconds: 250);

  final Color backgroundColor;
  final File image;
  final int maxWidth;
  final double pixelRatio;

  final bool selecting;
  final bool selected;

  final void Function() toggleSelection;

  const GalleryImage({
    @required this.image,
    Key key,
    this.selecting,
    this.selected,
    this.toggleSelection,
    this.maxWidth = 50,
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
              filterQuality: FilterQuality.high,
              fit: BoxFit.cover,
              image: ResizeImage.resizeIfNeeded(
                (maxWidth * pixelRatio).round(),
                null,
                FileImage(image),
              ),
            ),
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: toggleSelection,
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
}

class SelectionBar extends StatelessWidget {
  const SelectionBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend>();
    final clearSelection = backend.selection.clear;

    final selecting = context.select<Selection, bool>(
      (x) => x.selecting,
    );

    return WillPopScope(
      onWillPop: () async {
        if (selecting) clearSelection();
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
                    onPressed: clearSelection,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Consumer<Selection>(builder: (_, selection, __) {
                        return Text(
                          selection.size.toString(),
                          textScaleFactor: 1.1,
                        );
                      }),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    onLongPress: backend.deleteSelected,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 20,
                    ),
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

class SnackbarListener extends StatelessWidget {
  final Widget child;

  const SnackbarListener({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showSnackBar = Scaffold.of(context).showSnackBar;
    final backend = context.watch<Backend>();

    return StreamListener<GallerySnackbarMessage>(
      stream: backend.gallerySnackbarStream,
      onData: (message) => onData(message, showSnackBar),
      child: child,
    );
  }

  void onData(
    GallerySnackbarMessage message,
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(SnackBar)
        showSnackBar,
  ) {
    if (message is GalleryImagesAdded) {
      showSnackBar(SnackBar(
        // TODO: make correct plurals
        content: Text('Added ${message.amount} images'),
        action: SnackBarAction(
          onPressed: message.undo,
          label: "UNDO",
        ),
      ));
    } else if (message is GalleryImagesRemoved) {
      showSnackBar(SnackBar(
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
