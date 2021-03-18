import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:giftty/api/api.dart';
// import 'package:giftty/model/pageModel/banner_page_model.dart';
// import 'package:giftty/model/pageModel/modelpage.dart';
import 'bloc.dart';

class SectionBloc extends Bloc<SectionEvent, SectionState> {

  ApiRepository repository;

  // CategoryBloc(CategoryState initialState) : super(initialState);

  SectionBloc({@required this.repository}) : super(null);

  @override
  // TODO: implement initialState
  SectionState get initialState => SectionInitialState();

  @override
  Stream<SectionState> mapEventToState(SectionEvent event) async* {
    if (event is FetchSectionEvent) {
      yield SectionLoadingState();
      try {
        List<Section_Model> articles = await repository.getSection();
        yield SectionLoadedState(articles: articles);
      } catch (e) {
        yield SectionErrorState(message: e.toString());
      }
    }
  }

}