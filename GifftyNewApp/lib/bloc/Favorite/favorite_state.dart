import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
// import 'package:giftty/Favorite.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/Model/models.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class FavoriteState extends Equatable {
}

class FavoriteInitialState extends FavoriteState {
  @override
  List<Object> get props => [];
}

class FavoriteLoadingState extends FavoriteState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class FavoriteLoadedState extends FavoriteState {

  List<Section_Model> articles;

  FavoriteLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class FavoriteErrorState extends FavoriteState {

  String message;

  FavoriteErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}