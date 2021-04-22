import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/models.dart';
import 'package:giftty/api/apiRepository.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';
import 'bloc.dart';

class SliderBloc extends Bloc<SliderEvent, SliderState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  SliderBloc({@required this.repository}) : super(null);

  @override
  // ignore: override_on_non_overriding_member
  SliderState get initialState => SliderInitialState();

  @override
  Stream<SliderState> mapEventToState(SliderEvent event) async* {
    if (event is FetchSliderEvent) {
      yield SliderLoadingState();
      try {
        List<Model> articles = await repository.getSlider();
        print(articles[0].name);
        yield SliderLoadedState(articles: articles);
      } catch (e) {
        yield SliderErrorState(message: e.toString());
      }
    }
  }

}