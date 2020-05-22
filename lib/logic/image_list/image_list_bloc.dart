import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../image/image_bloc.dart';
import 'image_list_state.dart';

class ImageListBloc {
  ImageListState _state = ImageListState([]);

  final _stateStream = BehaviorSubject<ImageListState>();
  ValueStream<ImageListState> get stateStream => _stateStream.stream;

  final _imageAddedMessageStream = StreamController<ImageListMessage>();
  Stream<ImageListMessage> get imageAddedMessageStream =>
      _imageAddedMessageStream.stream;

  final _imageRemovedMessageStream = StreamController<ImageListMessage>();
  Stream<ImageListMessage> get imageRemovedMessageStream =>
      _imageRemovedMessageStream.stream;

  final _addInputStream = StreamController<List<ImageBloc>>();
  StreamSink<List<ImageBloc>> get add => _addInputStream.sink;

  final _removeInputStream = StreamController<List<ImageBloc>>();
  StreamSink<List<ImageBloc>> get remove => _removeInputStream.sink;

  ImageListBloc() {
    _stateStream.add(_state);

    _addInputStream.stream.forEach(_add);
    _removeInputStream.stream.forEach(_remove);
  }

  void _add(final List<ImageBloc> images) {
    if (images == null || images.isEmpty) return;

    _state = ImageListState(
      [...images, ..._state.list],
    );

    _stateStream.add(_state);

    _imageAddedMessageStream.add(
      ImageListMessage(
        changeAmount: images.length,
        undoAction: () {
          remove.add(images);
          print("""Undone add! ↩""");
        },
      ),
    );
  }

  void _remove(final List<ImageBloc> images) {
    if (images == null || images.isEmpty) return;

    final newList = [..._state.list];
    for (final x in images) {
      newList.remove(x);
    }

    _state = ImageListState(newList);
    _stateStream.add(_state);

    _imageRemovedMessageStream.add(
      ImageListMessage(
        changeAmount: images.length,
        undoAction: () async {
          add.add(images);
          print("""Undone remove! ↩""");
        },
      ),
    );
  }

  // Future<void> moveItem(int from, int to) async {
  //   final item = list[from];
  //   list.insert(to, item);
  //   list.removeAt(from);

  //   print(
  //     """🔀 Moved ${item.key} from $from to $to"""
  //     """ in list of size ${list.length}""",
  //   );

  //   notifyListeners();
  // }
}

class ImageListMessage {
  final int changeAmount;

  final void Function() undoAction;

  ImageListMessage({
    this.changeAmount,
    this.undoAction,
  });
}
