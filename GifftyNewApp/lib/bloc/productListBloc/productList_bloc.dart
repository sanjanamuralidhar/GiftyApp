import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:giftty/api/apiRepository.dart';
import 'package:giftty/bloc/notificationBloc/notification_event.dart';

import 'bloc.dart';

class ProductListBloc extends Bloc<ProductListEvent,ProductListState>   {
  ApiRepository repository;

  ProductListBloc({@required this.repository}) : super(null);

  @override
  Stream<ProductListState> mapEventToState(ProductListEvent event) async* {
///// Add To Cart
    try{
      if(event is OnAddToCartEvent){
        yield (AddingToCartState()); 
        await repository.addToCart(
          userid: event.userId,
          productVarientId: event.productVarientId,
          qty: event.qty,
          index: event.index,
        );
        yield (AddedToCartState());
      }

    }catch(e){
      yield AddToCartFailedState(message:e.toString());
    }
//// RemoveFrom Cart
    try{
      if(event is OnRemoveFromCartEvent){
        yield (RemovingFromCartState());
        await repository.removeFromCart(
          index:event.index,
          productVarientId: event.productvarientId,
          userid:event.userId,
          qty: event.qty,
        );
        yield (RemovedFromCartState());
      }
    }catch(e){
      yield RemovingFromCartFailed(message: e.toString());
    }
//// Get Products 
   try{
     if(event is GetProductEvent){
       yield(ProductLoadingState());
       await repository.getProduct(
         categoryId:event.categoryId,
         sort:event.sort,
         orderBy: event.orderBy,
         limit: event.limit,
         offset:event.offset,
         topRated:event.topRated,
       );
       yield (ProductLoadedState());
     }
   } catch(e){
     yield ProductErrorState(message: e.toString());
   }
    throw UnimplementedError();}


}

