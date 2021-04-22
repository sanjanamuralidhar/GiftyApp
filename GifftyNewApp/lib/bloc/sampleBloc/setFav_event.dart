abstract class FavEvent {}

// enum UserEvents { getUser, createUser, updateUser, deleteUser }



class OnAddToFav extends FavEvent{
  final String userId;
  final String productId;

  OnAddToFav({this.userId,this.productId, });
}

class AfterAddToFav extends FavEvent{
  AfterAddToFav();
}

class OnGetRating extends FavEvent {
  final String id;
  final String limit;
  final String offset;

  OnGetRating({this.id, this.limit, this.offset});
}

class RemoveFav extends FavEvent {
  final String userid;
  final String productId;
  final int index;

  RemoveFav({this.productId, this.userid,this.index});
}

class OnAddToCart extends FavEvent {
  final String userid;
  final String productVarientId;
  final String qty;
  final int index;

  OnAddToCart({this.userid, this.productVarientId, this.qty,this.index, });
}

class AfterAddToCart extends FavEvent {
  AfterAddToCart();
}
