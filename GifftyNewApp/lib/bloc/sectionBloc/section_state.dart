import 'package:flutter/material.dart';
// import 'package:giftty/model/api_result_model.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/Section_Model.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';

abstract class SectionState extends Equatable {}

class SectionInitialState extends SectionState {
  @override
  List<Object> get props => [];
}

class SectionLoadingState extends SectionState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class SectionLoadedState extends SectionState {

  List<Section_Model> articles;

  SectionLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class SectionErrorState extends SectionState {

  String message;

  SectionErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}