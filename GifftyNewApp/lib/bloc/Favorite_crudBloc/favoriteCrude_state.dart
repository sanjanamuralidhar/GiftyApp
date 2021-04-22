import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/models.dart';

abstract class FavoriteCrudState extends Equatable{}

class FavoriteCrudInitialState extends FavoriteCrudState{
  @override

  List<Object> get props => throw UnimplementedError();
}

class FavoriteCrudSavingState extends FavoriteCrudState{
  @override
  List<Object> get props => throw UnimplementedError();
}

class FavoriteCrudSavedState extends FavoriteCrudState{
  @override
  List<Object> get props => throw UnimplementedError();
}

class FavoriteCrudDeletingState extends FavoriteCrudState{
  @override
  List<Object> get props => throw UnimplementedError();
}

// ignore: must_be_immutable
class FavoriteCrudDeletedState extends FavoriteCrudState{
  Section_Model getData;

  FavoriteCrudDeletedState({@required this.getData});
  @override
  List<Object> get props => throw UnimplementedError();
}

class FavoriteCrudFailedState extends FavoriteCrudState{
  @override
  List<Object> get props => throw UnimplementedError();
}