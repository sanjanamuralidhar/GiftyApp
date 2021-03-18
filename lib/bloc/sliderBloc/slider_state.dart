import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/models.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class SliderState extends Equatable {}

class SliderInitialState extends SliderState {
  @override
  // TODO: implement props
  List<Object> get props => [];
}

class SliderLoadingState extends SliderState {
  @override
  // TODO: implement props
  List<Object> get props => [];
}


class SliderLoadedState extends SliderState {

  List<Model> articles;

  SliderLoadedState({@required this.articles});
  

  @override
  // TODO: implement props
  List<Object> get props => [articles];
}
class SliderLoadState extends SliderState {

  List<Widget> pages;

  SliderLoadState({@required this.pages});
  

  @override
  // TODO: implement props
  List<Object> get props => [pages];
}

// ignore: must_be_immutable
class SliderErrorState extends SliderState {

  String message;

  SliderErrorState({@required this.message});

  @override
  // TODO: implement props
  List<Object> get props => [message];
}