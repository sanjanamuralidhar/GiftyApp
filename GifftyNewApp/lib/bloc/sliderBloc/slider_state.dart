import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/models.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class SliderState extends Equatable {}

class SliderInitialState extends SliderState {
  @override
  List<Object> get props => [];
}

class SliderLoadingState extends SliderState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class SliderLoadedState extends SliderState {

  List<Model> articles;

  SliderLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class SliderErrorState extends SliderState {

  String message;

  SliderErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}