import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
// import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/Model/models.dart';
import 'package:giftty/api/apiRepository.dart';
import 'bloc.dart';

class ImageBloc extends Bloc<ImageEvent, ImageState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  ImageBloc({@required this.repository}) : super(null);

  @override
  // ignore: override_on_non_overriding_member
  ImageState get initialState =>  ImageInitialState();

  @override
  Stream<ImageState> mapEventToState(ImageEvent event) async* {
    if (event is FetchImageEvent) {
      yield ImageLoadingState();
      try {
        List<Model> articles = await repository.getOfferImages();
        yield ImageLoadedState(articles: articles);
      } catch (e) {
        yield ImageErrorState(message: e.toString());
      }
    }
  }

}