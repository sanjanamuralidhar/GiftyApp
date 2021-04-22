import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/Section_Model.dart';

abstract class TestState extends Equatable {}

class TestInitialState extends TestState {
  @override
  List<Object> get props => [];
}

class TestLoadingState extends TestState {
  @override
  List<Object> get props => [];
}

// ignore: must_be_immutable
class TestLoadedState extends TestState {

  List<Product> articles;

  TestLoadedState({@required this.articles});

  @override
  List<Object> get props => [articles];
}

// ignore: must_be_immutable
class TestErrorState extends TestState {

  String message;

  TestErrorState({@required this.message});

  @override
  List<Object> get props => [message];
}

