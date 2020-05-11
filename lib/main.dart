import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hello_world/editor.dart';
import 'package:flutter_hello_world/gallery.dart';
import 'package:hsluv/extensions.dart';
import 'package:provider/provider.dart';

import 'logic/images.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  final theme = ThemeData(
    brightness: Brightness.light,
    primaryColorBrightness: Brightness.light,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    accentColor: hsluvToRGBColor([75, 10, 50]),
    scaffoldBackgroundColor: hsluvToRGBColor([75, 0, 95]),
    unselectedWidgetColor: Colors.black26,
    colorScheme: ColorScheme.light(
      background: hsluvToRGBColor([75, 0, 95]),
      surface: Colors.white,
      primary: hsluvToRGBColor([75, 10, 50]),
      primaryVariant: hsluvToRGBColor([75, 10, 40]),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: hsluvToRGBColor([75, 10, 50]),
    ),
    canvasColor: Colors.white,
  );

  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
    accentColor: hsluvToRGBColor([75, 10, 90]),
    scaffoldBackgroundColor: Colors.black,
    cardColor: hsluvToRGBColor([75, 0, 6]),
    unselectedWidgetColor: Colors.white24,
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      surface: hsluvToRGBColor([75, 0, 10]),
      primary: hsluvToRGBColor([75, 10, 80]),
      primaryVariant: hsluvToRGBColor([75, 10, 60]),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: hsluvToRGBColor([75, 0, 10]),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: hsluvToRGBColor([75, 10, 80]),
    ),
    canvasColor: hsluvToRGBColor([75, 0, 10]),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: theme,
      darkTheme: darkTheme,
      home: Builder(builder: (context) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Theme.of(context).colorScheme.surface,
            systemNavigationBarIconBrightness:
                ThemeData.estimateBrightnessForColor(
              Theme.of(context).colorScheme.onSurface,
            ),
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: ChangeNotifierProvider<ValueNotifier<int>>(
              create: (context) => ValueNotifier<int>(0),
              child: Column(
                children: <Widget>[
                  Flexible(
                    child: ChangeNotifierProvider<ImageDataList>(
                      create: (_) => ImageDataList(),
                      child: Builder(builder: (context) {
                        final pages = <Widget>[
                          GalleryPage(),
                          EditorPage(),
                        ];
                        return Consumer<ValueNotifier<int>>(
                          builder: (context, _page, _) {
                            return IndexedStack(
                              index: _page.value,
                              children: pages,
                            );
                          },
                        );
                      }),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: Divider.createBorderSide(context),
                      ),
                    ),
                    child: Consumer<ValueNotifier<int>>(
                      builder: (context, _page, _) => BottomNavigationBar(
                        onTap: (index) => _page.value = index,
                        currentIndex: _page.value,
                        items: [
                          const BottomNavigationBarItem(
                            icon: const Icon(Icons.photo_library),
                            title: const Text("Gallery"),
                          ),
                          const BottomNavigationBarItem(
                            icon: const Icon(Icons.edit),
                            title: const Text("Editor"),
                          ),
                        ],
                        backgroundColor: Colors.transparent,
                        selectedItemColor: Theme.of(context).accentColor,
                        unselectedItemColor:
                            Theme.of(context).unselectedWidgetColor,
                        showSelectedLabels: false,
                        showUnselectedLabels: false,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              )),
        );
      }),
      debugShowCheckedModeBanner: false,
    );
  }
}
