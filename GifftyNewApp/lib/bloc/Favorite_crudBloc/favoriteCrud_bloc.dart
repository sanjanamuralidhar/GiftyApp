import 'package:giftty/Model/models.dart';
import 'package:giftty/api/apiRepository.dart';
import 'package:bloc/bloc.dart';
import 'package:giftty/bloc/bloc.dart';

class FavoriteCrudBloc extends Bloc<FavoriteCrudEvent, FavoriteCrudState> {
  ApiRepository repository;

  FavoriteCrudBloc({this.repository}) : super(null);

  // ignore: unused_field
  String _id = "";

  @override
  // ignore: override_on_non_overriding_member
  FavoriteCrudState get initialState => FavoriteCrudInitialState();


  @override
  Stream<FavoriteCrudState> mapEventToState(FavoriteCrudEvent event) async* {

    if(event is AddFavToCartEvent){
      yield FavoriteCrudSavingState();
      // UserModel user = await repository.addToCart(event.fav);
      yield FavoriteCrudSavedState();
    }

    if(event is RemoveFavFromCart ){
      yield FavoriteCrudDeletingState();
      // UserModel user = await repository.addToCart(event.fav);
  
      yield FavoriteCrudDeletedState(getData: null);
    }

    if(event is DeleteFavoriteEvent ){
      yield FavoriteCrudDeletingState();
      Section_Model getData = await repository.deleteFav(id : event.id);
      print(getData.id);
      print('........///// ....product details.... ////........${getData.productList.length}');
      yield FavoriteCrudDeletedState(getData: getData);
    }
  }
}

