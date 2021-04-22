import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/api/apiRepository.dart';
import 'bloc.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  ProductDetailBloc({@required this.repository}) : super(null);

  @override
    // ignore: override_on_non_overriding_member
    ProductDetailState get initialState => ProductDetailInitialState();

  @override
  Stream<ProductDetailState> mapEventToState(ProductDetailEvent event) async* {
    // if (event is FetchProductDetailEvent) {
    //   yield ProductDetailLoadingState();
    //   try {
    //     List<Product> articles = await repository.getCat();
    //     print(articles[0].name);
    //     yield ProductDetailLoadedState(articles: articles);
    //   } catch (e) {
    //     yield ProductDetailErrorState(message: e.toString());
    //   }
    // }
    if (event is ParameterProductDetailEvent) {
      print('weeeeeeee ${event.categoryId},${event.limit},${event.id},${event.offset},${event.isSimilar}');
      yield ProductDetailLoadingState();
      await Future.delayed(Duration(seconds: 1));
      try {
        print('dfvbdjkfvbdjf fdb fdfvdfvbdfhgviodf ');
        List<Product> articles = await repository.getProductDetail(
          categoryId : event.categoryId,
          limit : event.limit,
          id: event.id,
            offset:event.offset,
            isSimilar:event.isSimilar
        );
        print('weeeeeeee ${event.categoryId},${event.limit},${event.id},${event.offset},${event.isSimilar}');
        print(articles[0].name);
        print('........///// ....product details.... ////........${articles.length}');
        yield ProductDetailLoadedState(articles: articles);
      } catch (e) {
        yield ProductDetailErrorState(message: e.toString());
      }
    }
  }
}
