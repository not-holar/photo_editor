import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hsluv/extensions.dart';
import 'package:provider/provider.dart';

import 'logic/app_bloc.dart';
import 'views/editor/editor.dart' as _editor;
import 'views/gallery/gallery.dart' as _gallery;

void main() => runApp(App());

class App extends StatelessWidget {
  static ThemeData get baseTheme => ThemeData(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        primarySwatch: Colors.grey,
      );

  static ThemeData get darkTheme => baseTheme.copyWith(
        brightness: Brightness.dark,
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

  static ThemeData get lightTheme => baseTheme.copyWith(
        brightness: Brightness.light,
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
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => ValueNotifier<int>(0),
              ),
              Provider(
                create: (context) => AppBloc(),
              ),
            ],
            child: Column(children: [
              Expanded(
                child: AppPageSelector(children: [
                  _gallery.Main(),
                  _editor.Main(),
                ]),
              ),
              const AppNavigationBar(),
            ]),
          ),
        );
      }),
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<ValueNotifier<int>>();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: Divider.createBorderSide(context)),
      ),
      child: BottomNavigationBar(
        onTap: (index) => currentIndex.value = index,
        currentIndex: currentIndex.value,
        selectedItemColor: Theme.of(context).accentColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            title: Text("Gallery"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            title: Text("Editor"),
          ),
        ],
      ),
    );
  }
}

class AppPageSelector extends StatelessWidget {
  final List<Widget> children;

  const AppPageSelector({Key key, this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: context.watch<ValueNotifier<int>>().value,
      children: children,
    );
  }
}
