import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
// import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/api/apiRepository.dart';

import '../bloc.dart';

class FavBloc extends Bloc<FavEvent, FavState> {
  ApiRepository repository;
 FavBloc({@required this.repository}) : super(null);

  @override
  Stream<FavState> mapEventToState(event) async* {
    
//to do now 19.4.21 removed name to samplebloc to fav bloc
try{
    if (event is OnAddToFav) {
      yield FavSettingFav();
      await repository.setFav(
        uId: event.userId,
        prodId: event.productId
      );
          yield FavSetFav();
        } }catch (error) {
          yield AddToFavFailed(message:error.toString());
      }

      try {
      if (event is RemoveFav) {
        yield (FavRemovingFav());
         await repository.removingfromFav(
           userid: event.userid,
           productId: event.productId,
           index: event.index,
        );
        yield (FavRemoveFav());
      }
    } catch (e) {
      yield FavRemoveFailed(message: e.toString());
    }

  ///Event for login
 try {
      if (event is OnAddToCart) {
        yield (FavAddingToCart());
         await repository.addToCart(
          userid: event.userid,
          productVarientId: event.productVarientId,
          qty: event.qty,
          index: event.index,
        );
        yield (FavAddedToCart());
      }
    } catch (e) {
      yield AddToCartFailed(message: e.toString());
    }

  }
}
