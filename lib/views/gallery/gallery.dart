import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_stream_listener/flutter_stream_listener.dart';

import 'package:provider/provider.dart';

import 'package:flutter_hello_world/logic/image_list/image_list_state.dart';
import 'package:flutter_hello_world/basic_widgets/circular_check_box.dart';
import 'package:flutter_hello_world/logic/app_bloc.dart';
import 'package:flutter_hello_world/logic/image/image_bloc.dart';
import 'package:flutter_hello_world/logic/image_list/image_list_bloc.dart';

class Main extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ValueNotifier<Set<ImageBloc>>>(
          create: (_) => ValueNotifier(<ImageBloc>{}),
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
          onPressed: () => context.read<AppBloc>().addFromPicker.add(null),
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

    return StreamBuilder<ImageListState>(
      stream: context.watch<AppBloc>().imageListStream,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const CircularProgressIndicator();
        }

        return CustomScrollView(
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
                      snapshot.data.list[index],
                      maxWidth: 150,
                      pixelRatio: devicePixelRatio,
                      backgroundColor: _imageBackgroundColor,
                    ),
                    childCount: snapshot.data.list.length,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class GalleryImage extends StatelessWidget {
  static const curve = Curves.fastOutSlowIn;
  static const duration = Duration(milliseconds: 250);

  final Color backgroundColor;
  final ImageBloc image;
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
    final selecting = context.select<ValueNotifier<Set<ImageBloc>>, bool>(
      (x) => x.value.isNotEmpty,
    );
    final selected = context.select<ValueNotifier<Set<ImageBloc>>, bool>(
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
                FileImage(image.state.file),
              ),
            ),
          ),
        ),
        Material(
          type: MaterialType.transparency,
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
    ImageBloc image, {
    bool wasSelected,
  }) async {
    final v = context.read<ValueNotifier<Set<ImageBloc>>>();
    if (wasSelected) {
      v.value = v.value.difference(<ImageBloc>{image});
    } else {
      v.value = v.value.union(<ImageBloc>{image});
    }
  }
}

class SelectionBar extends StatelessWidget {
  const SelectionBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selecting = context
        .select<ValueNotifier<Set<ImageBloc>>, bool>((x) => x.value.isNotEmpty);
    return WillPopScope(
      onWillPop: () async {
        if (selecting) {
          context.read<ValueNotifier<Set<ImageBloc>>>().value = {};
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
                      context.read<ValueNotifier<Set<ImageBloc>>>().value = {};
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Builder(builder: (context) {
                        return Text(
                          context
                              .select<ValueNotifier<Set<ImageBloc>>, int>(
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
                      // TODO: fix selection deleting
                      //   context.read<ImageListBloc>().remove(
                      //       context.read<ValueNotifier<Set<ImageData>>>().value);
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

class SnackbarListener extends StatelessWidget {
  final Widget child;

  const SnackbarListener({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showSnackBar = Scaffold.of(context).showSnackBar;
    final appBloc = context.watch<AppBloc>();

    return StreamListener(
      stream: appBloc.imagesAddedMessageStream,
      onData: makeMessageProcessor(
        showSnackBar,
        addedMessageSnackbarBuilder,
      ),
      child: StreamListener(
        stream: appBloc.imagesRemovedMessageStream,
        onData: makeMessageProcessor(
          showSnackBar,
          removedMessageSnackbarBuilder,
        ),
        child: child,
      ),
    );
  }

  SnackBar addedMessageSnackbarBuilder(ImageListMessage message) {
    return SnackBar(
      // TODO: make correct plurals
      content: Text('Added ${message.changeAmount} images'),
      action: SnackBarAction(
        onPressed: message.undoAction,
        label: "UNDO",
      ),
    );
  }

  SnackBar removedMessageSnackbarBuilder(ImageListMessage message) {
    return SnackBar(
      // behavior: SnackBarBehavior.floating,
      content: Text(
        'Removed ${message.changeAmount} images',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      action: SnackBarAction(
        onPressed: message.undoAction,
        label: "UNDO",
        textColor: Colors.white,
      ),
      backgroundColor: Colors.redAccent,
    );
  }

  Null Function(ImageListMessage) makeMessageProcessor(
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(SnackBar)
        showSnackBar,
    SnackBar Function(ImageListMessage) snackbarBuilder,
  ) {
    return (ImageListMessage message) {
      showSnackBar(snackbarBuilder(message)).closed.then(
        (reason) {
          if (reason != SnackBarClosedReason.action) {
            message?.ignoreAction?.call();
          }
        },
      );
    };
  }
}
