import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/Section_Model.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class CategoryState extends Equatable {}

class CategoryInitialState extends CategoryState {
  @override
  // ignore: todo
  // TODO: implement props
  List<Object> get props => [];
}

class CategoryLoadingState extends CategoryState {
  @override
  // ignore: todo
  // TODO: implement props
  List<Object> get props => [];
}

// ignore: must_be_immutable
class CategoryLoadedState extends CategoryState {

  List<Product> articles;

  CategoryLoadedState({@required this.articles});

  @override
  // ignore: todo
  // TODO: implement props
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class CategoryErrorState extends CategoryState {

  String message;

  CategoryErrorState({@required this.message});

  @override
  // ignore: todo
  // TODO: implement props
  List<Object> get props => [message];
}