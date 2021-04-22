import 'package:equatable/equatable.dart';

abstract class SectionEvent extends Equatable{}

class FetchSectionEvent extends SectionEvent {
  @override
  List<Object> get props => null;
}