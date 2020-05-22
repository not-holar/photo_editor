import 'package:flutter/foundation.dart';

class Selection extends Iterable<int> with ChangeNotifier {
  final Set<int> _ids = {};

  bool Function(int id) get has => _ids.contains;

  bool get selecting => _ids.isNotEmpty;
  int get size => _ids.length;

  void add(int id) {
    if (_ids.add(id)) {
      notifyListeners();
    }
  }

  void remove(int id) {
    if (_ids.remove(id)) {
      notifyListeners();
    }
  }

  void toggle(int id) {
    if (!_ids.add(id)) {
      _ids.remove(id);
    }
    notifyListeners();
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }

  @override
  Iterator<int> get iterator => _ids.iterator;
}
