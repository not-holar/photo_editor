import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'package:flutter_hello_world/basic_widgets/circular_check_box.dart';
import 'package:flutter_hello_world/logic/selection.dart';
import 'package:flutter_hello_world/logic/backend.dart';

import 'snackbar_listener.dart';

class Gallery extends StatelessWidget {
  const Gallery({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<List<MapEntry<int, File>>>>.value(
          value: backend.galleryImages,
        ),
        ChangeNotifierProvider<Selection>.value(
          value: backend.selection,
        ),
      ],
      child: const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.expand(),
        ),
        body: Material(
          type: MaterialType.transparency,
          child: SnackbarListener(
            child: GalleryGrid(
              padding: EdgeInsets.fromLTRB(4, 44, 4, 100),
            ),
          ),
        ),
        floatingActionButton: GalleryFab(),
        bottomNavigationBar: SelectionBar(),
      ),
    );
  }
}

class GalleryFab extends StatelessWidget {
  const GalleryFab({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend>();
    final color = Theme.of(context).colorScheme.surface;

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      // transitionDuration: const Duration(milliseconds: 1500),
      closedShape: const CircleBorder(),
      closedColor: color,
      closedBuilder: (context, open) {
        return IconButton(
          onPressed: open,
          tooltip: 'Expand Gallery Menu',
          padding: const EdgeInsets.all(16),
          icon: const Icon(Icons.add),
        );
      },
      openColor: color,
      openBuilder: (context, close) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Builder(builder: (context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton.icon(
                  onPressed: () async {
                    try {
                      if (await backend.addFromPicker()) close();
                    } catch (error) {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text('$error')),
                      );
                    }
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  label: const Text(
                    'Add from Gallery',
                    textScaleFactor: 1.5,
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_library),
                  ),
                ),
                const Divider(
                  height: 40,
                  indent: 32,
                  endIndent: 32,
                  thickness: 1,
                ),
                FlatButton.icon(
                  onPressed: () async {
                    try {
                      if (await backend.addFromCamera()) close();
                    } catch (error) {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('$error'),
                        ),
                      );
                    }
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  label: const Text(
                    'Add from Camera',
                    textScaleFactor: 1.5,
                  ),
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_camera),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class GalleryGrid extends StatelessWidget {
  static final Color _imageBackgroundColor =
      Colors.grey.shade400.withOpacity(.5);

  final EdgeInsets padding;

  static const double maxCrossAxisExtent = 150;
  static const double crossAxisSpacing = 4;
  static const double mainAxisSpacing = crossAxisSpacing;

  const GalleryGrid({
    Key key,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backend = context.watch<Backend>();
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Consumer<ValueNotifier<List<MapEntry<int, File>>>>(
        builder: (context, list, _) {
      final idIndexMap = HashMap.fromIterables(
        list.value.map((entry) => entry.key),
        Iterable<int>.generate(list.value.length),
      );
      return LayoutBuilder(builder: (context, constraints) {
        final crossAxisCount = (( //
                    constraints.maxWidth -
                        padding.horizontal -
                        MediaQuery.of(context).viewInsets.horizontal //
                ) /
                (maxCrossAxisExtent + crossAxisSpacing) //
            )
            .ceil();

        return CustomScrollView(
          key: const PageStorageKey(GalleryGrid),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              sliver: SliverPadding(
                padding: padding,
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    mainAxisSpacing: mainAxisSpacing,
                    crossAxisSpacing: crossAxisSpacing,
                    maxCrossAxisExtent: maxCrossAxisExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return GalleryItem(
                        key: ValueKey<int>(list.value[index].key),
                        entry: list.value[index],
                        index: index,
                        backend: backend,
                        imageBackgroundColor: _imageBackgroundColor,
                        devicePixelRatio: devicePixelRatio,
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                      );
                    },
                    childCount: list.value.length,
                    findChildIndexCallback: (key) =>
                        idIndexMap[(key as ValueKey<int>).value],
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            ),
          ],
        );
      });
    });
  }
}

class GalleryItem extends StatefulWidget {
  const GalleryItem({
    Key key,
    @required this.entry,
    @required this.index,
    @required this.imageBackgroundColor,
    @required this.devicePixelRatio,
    @required this.backend,
    @required this.crossAxisCount,
    @required this.crossAxisSpacing,
    @required this.mainAxisSpacing,
  }) : super(key: key);

  final Color imageBackgroundColor;
  final double devicePixelRatio;
  final Backend backend;
  final MapEntry<int, File> entry;
  final int index;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  _GalleryItemState createState() => _GalleryItemState();
}

class _GalleryItemState extends State<GalleryItem> {
  @override
  void initState() {
    super.initState();
    previousIndex = widget.index;
  }

  final _globalKey = GlobalKey();

  ImageProvider image;

  int previousIndex;
  Offset midFlightOffset = Offset.zero;

  bool currentlyDragging = false;

  Offset offsetFromIndices(int last, int current) {
    Offset position(int index) => Offset(
          (index % widget.crossAxisCount).toDouble(),
          (index / widget.crossAxisCount).floorToDouble(),
        );

    return (last == current)
        ? Offset.zero
        : (position(current) - position(last));
  }

  @override
  Widget build(BuildContext context) {
    final offset = offsetFromIndices(previousIndex, widget.index);
    previousIndex = widget.index;

    return Ink(
      color: widget.imageBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;

          // Size should never change so it's fine to cache it for as long as the state lives
          image ??= ResizeImage.resizeIfNeeded(
            (size * widget.devicePixelRatio).round(),
            null,
            FileImage(widget.entry.value),
          );

          return TweenAnimationBuilder<Offset>(
            key: ValueKey(widget.index),
            duration: currentlyDragging
                ? const Duration()
                : Duration(milliseconds: 200 + (150 * offset.distance).floor()),
            curve: Curves.fastOutSlowIn,
            tween: Tween<Offset>(
              begin: -offset.scale(
                    size + widget.crossAxisSpacing,
                    size + widget.mainAxisSpacing,
                  ) +
                  midFlightOffset,
              end: Offset.zero,
            ),
            builder: (context, offset, child) {
              midFlightOffset = offset;

              return Transform.translate(
                offset: offset,
                child: child,
              );
            },
            child: Consumer<Selection>(
              key: _globalKey,
              builder: (context, selection, _) =>
                  LongPressDraggable<MapEntry<int, File>>(
                data: widget.entry,
                onDragStarted: () => currentlyDragging = true,
                onDragEnd: (_) => currentlyDragging = false,
                feedback: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.fastOutSlowIn,
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double tween, child) {
                    final borderWidth = tween * widget.crossAxisSpacing;

                    return Transform.translate(
                      offset: Offset(-borderWidth, -borderWidth),
                      child: SizedBox(
                        width: size + borderWidth * 2,
                        height: size + borderWidth * 2,
                        child: Material(
                          elevation: 8 * tween,
                          // color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(borderWidth),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: ChangeNotifierProvider.value(
                    value: selection,
                    child: Consumer<Selection>(
                      builder: (context, selection, _) => GalleryImage(
                        image: image,
                        selecting: selection.selecting,
                        selected: selection.has(widget.entry.key),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: const SizedBox.expand(),
                child: DragTarget<MapEntry<int, File>>(
                  onWillAccept: (entry) {
                    widget.backend.moveImage(entry.key, widget.index);
                    return false;
                  },
                  builder: (context, _, __) {
                    return GalleryImage(
                      image: image,
                      selecting: selection.selecting,
                      selected: selection.has(widget.entry.key),
                      onTap: () => selection.toggle(widget.entry.key),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  static const curve = Curves.fastOutSlowIn;
  static const duration = Duration(milliseconds: 250);

  final ImageProvider image;

  final VoidCallback onTap;

  final bool selecting;
  final bool selected;

  const GalleryImage({
    @required this.image,
    Key key,
    this.selecting,
    this.selected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedPadding(
          padding: selected ? const EdgeInsets.all(15) : EdgeInsets.zero,
          duration: duration,
          curve: curve,
          child: Image(
            filterQuality: FilterQuality.high,
            fit: BoxFit.cover,
            image: image,
          ),
        ),
        if (onTap != null)
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
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
          position: DecorationPosition.foreground,
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
                      child: Consumer<Selection>(
                        builder: (_, selection, __) => Text(
                          selection.size.toString(),
                          textScaleFactor: 1.1,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: backend.deleteSelected,
                    tooltip: "Delete Selected Images",
                    icon: const Icon(Icons.delete_outline, size: 20),
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

class TopShadow extends StatelessWidget {
  const TopShadow({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Visibility(
        visible: constraints.maxHeight != 0,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.background.withOpacity(0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
        ),
      );
    });
  }
}
