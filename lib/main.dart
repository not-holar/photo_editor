import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hello_world/editor.dart';
import 'package:flutter_hello_world/gallery.dart';
import 'package:hsluv/extensions.dart';

void main() => runApp(App());

Color bottomNavigationColor() =>
    WidgetsBinding.instance.window.platformBrightness == Brightness.dark
        ? hsluvToRGBColor([75, 0, 10])
        : Colors.white;

final ThemeData themeDataLight = ThemeData(
  brightness: Brightness.light,
  primaryColorBrightness: Brightness.light,
  splashFactory: InkRipple.splashFactory,
  highlightColor: Colors.transparent,
  accentColor: hsluvToRGBColor([75, 10, 50]),
  scaffoldBackgroundColor: hsluvToRGBColor([75, 0, 95]),
  unselectedWidgetColor: Colors.black26,
  colorScheme: ColorScheme.light(
    primary: hsluvToRGBColor([75, 10, 50]),
    primaryVariant: hsluvToRGBColor([75, 10, 40]),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: hsluvToRGBColor([75, 10, 50]),
  ),
);

final ThemeData themeData = ThemeData(
  brightness: Brightness.dark,
  splashFactory: InkRipple.splashFactory,
  highlightColor: Colors.transparent,
  accentColor: hsluvToRGBColor([75, 10, 90]),
  scaffoldBackgroundColor: Colors.black,
  cardColor: hsluvToRGBColor([75, 0, 6]),
  unselectedWidgetColor: Colors.white24,
  colorScheme: ColorScheme.dark(
    primary: hsluvToRGBColor([75, 10, 80]),
    primaryVariant: hsluvToRGBColor([75, 10, 60]),
    surface: hsluvToRGBColor([75, 0, 10]),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: hsluvToRGBColor([75, 10, 80]),
  ),
  canvasColor: hsluvToRGBColor([75, 0, 10]),
);

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: themeDataLight,
      darkTheme: themeData,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              WidgetsBinding.instance.window.platformBrightness ==
                      Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
          systemNavigationBarColor: bottomNavigationColor(),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Home(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _children = [
    GalleryPage(),
    EditorPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: _children[_currentIndex],
        ),
        Container(
          decoration: BoxDecoration(
            color: bottomNavigationColor(),
            border: Border(
              top: Divider.createBorderSide(context),
            ),
          ),
          child: BottomNavigationBar(
            onTap: onTabTapped,
            currentIndex: _currentIndex,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.photo_library), title: Text("Gallery")),
              BottomNavigationBarItem(
                  icon: Icon(Icons.edit), title: Text("Editor")),
            ],
            backgroundColor: bottomNavigationColor(),
            selectedItemColor: Theme.of(context).accentColor,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
