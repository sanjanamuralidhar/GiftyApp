abstract class ProductListEvent{}

class OnAddToCartEvent extends ProductListEvent{
  final String userId;
  final String productVarientId;
  final String qty;
  final int index;

  OnAddToCartEvent({this.userId,this.productVarientId, this.qty,this.index,});
}

class OnRemoveFromCartEvent extends ProductListEvent{
  final int index;
  final String productvarientId;
  final String userId;
  final String qty;

  OnRemoveFromCartEvent({this.productvarientId, this.userId, this.qty, this.index, });  
}

class GetProductEvent extends ProductListEvent{
  final String categoryId;
  final String sort;
  final String order;
  final String orderBy;
  final String limit;
  final String offset;
  final String topRated;

  GetProductEvent({this.categoryId, this.sort, this.order, this.orderBy, this.limit, this.offset, this.topRated});
}

