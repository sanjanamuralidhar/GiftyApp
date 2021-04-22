import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
// import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/Model/models.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class ImageState extends Equatable {}

class ImageInitialState extends ImageState {
  @override
  List<Object> get props => [];
}

class ImageLoadingState extends ImageState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class ImageLoadedState extends ImageState {

  List<Model> articles;

  ImageLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class ImageErrorState extends ImageState {

  String message;

  ImageErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}