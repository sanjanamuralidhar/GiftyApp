import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable{}

class FetchProductDetailEvent extends ProductDetailEvent {
  @override
  List<Object> get props => null;
}
class ParameterProductDetailEvent extends ProductDetailEvent {
  final String categoryId;
  final String limit;
  final String offset;
  final String id;
  final String isSimilar;

  ParameterProductDetailEvent({this.categoryId,this.limit,this.offset,this.id,this.isSimilar});


  @override
  List<Object> get props => throw UnimplementedError();

}