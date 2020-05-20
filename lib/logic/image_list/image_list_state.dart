import '../image/image_bloc.dart';

class ImageListState {
  final List<ImageBloc> _list;
  List<ImageBloc> get list => _list;

  ImageListState(this._list);

  @override
  String toString() => 'ImageListState(${_list.toString()})';
}
