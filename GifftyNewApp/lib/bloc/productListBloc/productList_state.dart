abstract class ProductListState{}

class ProductListInitialState extends ProductListState{}

class AddingToCartState extends ProductListState{}
class AddedToCartState extends ProductListState{}
class AddToCartFailedState extends ProductListState{
  final String message;

  AddToCartFailedState({this.message});
}

class RemovingFromCartState extends ProductListState{}
class RemovedFromCartState extends ProductListState{}
class RemovingFromCartFailed extends ProductListState{
  final String message;

  RemovingFromCartFailed({this.message});
}

class ProductLoadingState extends ProductListState{}
class ProductLoadedState extends ProductListState{}
class ProductErrorState extends ProductListState{
  final String message;

  ProductErrorState({this.message});
}