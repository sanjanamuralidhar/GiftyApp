import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/Section_Model.dart';

abstract class ProductDetailState extends Equatable {}

class ProductDetailInitialState extends ProductDetailState {
  @override
  List<Object> get props => [];
}

class ProductDetailLoadingState extends ProductDetailState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class ProductDetailLoadedState extends ProductDetailState {

  List<Product> articles;

  ProductDetailLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class ProductDetailErrorState extends ProductDetailState {

  String message;

  ProductDetailErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}

