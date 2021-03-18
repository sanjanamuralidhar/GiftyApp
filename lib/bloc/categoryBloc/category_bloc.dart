import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/api/api.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';
import 'bloc.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  CategoryBloc({@required this.repository}) : super(null);

  @override
  // TODO: implement initialState
  CategoryState get initialState => CategoryInitialState();

  @override
  Stream<CategoryState> mapEventToState(CategoryEvent event) async* {
    if (event is FetchCategoryEvent) {
      yield CategoryLoadingState();
      try {
        List<Product> articles = await repository.getCat();
        print(articles[0].name);
        yield CategoryLoadedState(articles: articles);
      } catch (e) {
        yield CategoryErrorState(message: e.toString());
      }
    }
  }

}