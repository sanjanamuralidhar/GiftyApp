import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/Model/models.dart';
import 'package:giftty/api/apiRepository.dart';
import 'bloc.dart';

////////////////we are using this bloc at fav page//////////////
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  FavoriteBloc({@required this.repository}) : super(null);

  @override
  // ignore: override_on_non_overriding_member
  FavoriteState get initialState =>  FavoriteInitialState();

  @override
  Stream<FavoriteState> mapEventToState(FavoriteEvent event) async* {
    if (event is FetchFavoriteEvent) {
      yield FavoriteLoadingState();
      try {
        List<Section_Model> articles = await repository.getFav();
        print('......../////fav////........${articles.length}');
        yield FavoriteLoadedState(articles: articles);
      } catch (e) {
        yield FavoriteErrorState(message: e.toString());
      }
    }
  }

}