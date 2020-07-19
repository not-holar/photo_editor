import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';

import 'package:hsluv/extensions.dart';
import 'package:provider/provider.dart';

import 'logic/backend.dart';
import 'views/editor/editor.dart' show Editor;
import 'views/gallery/gallery.dart' show Gallery;

void main() {
  // timeDilation = 10.0;
  runApp(App());
}

class App extends StatelessWidget {
  static ThemeData get darkTheme => ThemeData(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
        backgroundColor: Colors.black,
        accentColor: hsluvToRGBColor(const [75, 10, 90]),
        scaffoldBackgroundColor: Colors.black,
        cardColor: hsluvToRGBColor(const [75, 0, 6]),
        unselectedWidgetColor: Colors.white24,
        colorScheme: ColorScheme.dark(
          background: Colors.black,
          surface: hsluvToRGBColor(const [75, 0, 10]),
          primary: hsluvToRGBColor(const [75, 10, 80]),
          primaryVariant: hsluvToRGBColor(const [75, 10, 60]),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: hsluvToRGBColor(const [75, 0, 10]),
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: hsluvToRGBColor(const [75, 10, 80]),
          foregroundColor: Colors.black54,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: hsluvToRGBColor(const [75, 10, 80]),
          actionTextColor: Colors.black,
          contentTextStyle: const TextStyle(
            color: Colors.black,
          ),
        ),
        canvasColor: hsluvToRGBColor(const [75, 0, 10]),
      );

  static ThemeData get lightTheme => ThemeData(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        primarySwatch: Colors.grey,
        brightness: Brightness.light,
        backgroundColor: hsluvToRGBColor(const [75, 0, 95]),
        accentColor: hsluvToRGBColor(const [75, 10, 50]),
        scaffoldBackgroundColor: hsluvToRGBColor(const [75, 0, 95]),
        unselectedWidgetColor: Colors.black26,
        colorScheme: ColorScheme.light(
          background: hsluvToRGBColor(const [75, 0, 95]),
          surface: Colors.white,
          primary: hsluvToRGBColor(const [75, 10, 50]),
          primaryVariant: hsluvToRGBColor(const [75, 10, 40]),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: hsluvToRGBColor(const [75, 10, 50]),
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: hsluvToRGBColor(const [75, 10, 50]),
          actionTextColor: Colors.white,
          contentTextStyle: const TextStyle(
            color: Colors.white,
          ),
        ),
        canvasColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
        title: 'Flutter Demo',
        theme: lightTheme,
        darkTheme: darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AppHome());
  }
}

class AppHome extends StatelessWidget {
  const AppHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ValueNotifier<int>(0),
        ),
        Provider(
          create: (_) => Backend(),
          dispose: (_, Backend x) => x.dispose(),
          lazy: false,
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: ThemeData.estimateBrightnessForColor(
              theme.colorScheme.background),
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: ThemeData.estimateBrightnessForColor(
              theme.colorScheme.onBackground),
          systemNavigationBarColor: theme.colorScheme.surface,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              ThemeData.estimateBrightnessForColor(theme.colorScheme.onSurface),
        ),
        child: Column(
          children: const [
            Expanded(
              child: AppPageSwitcher(
                children: [
                  Gallery(),
                  Editor(),
                ],
              ),
            ),
            AppNavigationBar(),
          ],
        ),
      ),
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<ValueNotifier<int>>();
    final mediaQuery = MediaQuery.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: Divider.createBorderSide(context),
        ),
      ),
      child: BottomNavigationBar(
        onTap: (index) => currentIndex.value = index,
        currentIndex: currentIndex.value,
        selectedItemColor: Theme.of(context).accentColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.fromLTRB(
                2,
                2,
                2,
                mediaQuery.viewInsets.bottom,
              ),
              child: Icon(
                Icons.photo_library,
                size: 22,
              ),
            ),
            title: const Text("Gallery"),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.fromLTRB(
                2,
                2,
                2,
                mediaQuery.viewInsets.bottom,
              ),
              child: Icon(
                Icons.edit,
                size: 22,
              ),
            ),
            title: const Text("Editor"),
          ),
        ],
      ),
    );
  }
}

class AppPageSwitcher extends StatelessWidget {
  final List<Widget> children;

  const AppPageSwitcher({Key key, this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.background;

    return WillPopScope(
      onWillPop: () async {
        final selectedPage = context.read<ValueNotifier<int>>();

        if (selectedPage.value != 0) {
          selectedPage.value = 0;
          return false;
        } else {
          return true;
        }
      },
      child: Builder(builder: (context) {
        return PageTransitionSwitcher(
          // duration: const Duration(milliseconds: 1000),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return ColoredBox(
              color: background,
              child: FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              ),
            );
          },
          child: children[context.watch<ValueNotifier<int>>().value],
        );
      }),
    );
  }
}
