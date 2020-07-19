import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Editor extends StatelessWidget {
  const Editor({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: const SizedBox.expand(),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}
