import 'package:equatable/equatable.dart';

abstract class ImageEvent extends Equatable{}

class FetchImageEvent extends ImageEvent {
  @override
  List<Object> get props => null;
}