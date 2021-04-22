import 'package:flutter/cupertino.dart';
// import 'package:flutter/rendering.dart';
// import 'package:giftty/Model/Section_Model.dart';

abstract class FavState {}

class FavInitialState extends FavState{}


class FavGettingReview extends FavState{}

class FavGetReview extends FavState{}

class FavSettingFav extends FavState{}

class FavSetFav extends FavState{}

class FavSetCompleted extends FavState{}

class AddToFavFailed extends FavState{
  String message;

  AddToFavFailed({@required this.message});

  @override
  // ignore: override_on_non_overriding_member
  List<Object> get props => [message];
}

class FavRemovingFav extends FavState{}

class FavRemoveFav extends FavState{
}

class FavRemoveFailed extends FavState {

  String message;

  FavRemoveFailed({@required this.message});

  @override
  // ignore: override_on_non_overriding_member
  List<Object> get props => [message];
}

class FavAddingToCart extends FavState{}

class FavAddedToCart extends FavState{}

class AddToCartFailed extends FavState{
  String message;

  AddToCartFailed({@required this.message});

  @override
  // ignore: override_on_non_overriding_member
  List<Object> get props => [message];
}