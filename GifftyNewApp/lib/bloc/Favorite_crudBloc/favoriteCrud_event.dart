
import 'package:equatable/equatable.dart';
import 'package:giftty/Model/models.dart';

abstract class FavoriteCrudEvent extends Equatable{}

class AddFavToCartEvent extends FavoriteCrudEvent{
  final Section_Model fav;
  AddFavToCartEvent({this.fav});

  @override
  // ignore: todo
  // TODO: implement props
  List<Object> get props => throw UnimplementedError();
}

class RemoveFavFromCart extends FavoriteCrudEvent{
  final Section_Model fav;
  RemoveFavFromCart({this.fav});

  @override
  List<Object> get props => throw UnimplementedError();
}

class DeleteFavoriteEvent extends FavoriteCrudEvent{
  final String id;
  DeleteFavoriteEvent({this.id});

  @override
  List<Object> get props => throw UnimplementedError();

}
