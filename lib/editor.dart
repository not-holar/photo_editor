import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditorPage extends StatefulWidget {
  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: const Center(
        child: const Text("Editor"),
      ),
    );
  }
}
