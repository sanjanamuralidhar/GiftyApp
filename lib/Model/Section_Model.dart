import 'package:giftty/Helper/String.dart';

class Section_Model {
  String id,
      title,
      varientId,
      qty,
      productId,
      perItemTotal,
      perItemPrice,
      style,
      short_desc;
  List<Product> productList;
  List<Filter> filterList;
  List<String> selectedId = [];
  int offset, totalItem;

  Section_Model(
      {this.id,
      this.title,
      this.productList,
      this.varientId,
      this.qty,
      this.productId,
      this.perItemTotal,
      this.perItemPrice,
      this.style,
      this.short_desc,
      this.totalItem,
      this.offset,
      this.selectedId,
      this.filterList});

  factory Section_Model.fromJson(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => new Product.fromJson(data))
        .toList();

    var flist = (parsedJson[FILTERS] as List);
    List<Filter> filterList = [];
    if (flist == null || flist.isEmpty)
      filterList = [];
    else
      filterList = flist.map((data) => new Filter.fromJson(data)).toList();
    List<String> selected = [];
    return Section_Model(
        id: parsedJson[ID],
        title: parsedJson[TITLE],
        style: parsedJson[STYLE],
        short_desc: parsedJson[SHORT_DESC],
        productList: productList,
        offset: 0,
        totalItem: 0,
        filterList: filterList,
        selectedId: selected);
  }

  factory Section_Model.fromCart(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => new Product.fromJson(data))
        .toList();

    return Section_Model(
        id: parsedJson[ID],
        varientId: parsedJson[PRODUCT_VARIENT_ID],
        qty: parsedJson[QTY],
        perItemTotal: "0",
        perItemPrice: "0",
        productList: productList);
  }

  factory Section_Model.fromFav(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => new Product.fromJson(data))
        .toList();

    return Section_Model(
        id: parsedJson[ID],
        productId: parsedJson[PRODUCT_ID],
        productList: productList);
  }
}

class Product {
  String id,
      name,
      desc,
      image,
      catName,
      type,
      rating,
      noOfRating,
      attrIds,
      tax,
      categoryId,
      shortDescription;
  List<String> otherImage;
  List<Product_Varient> prVarientList;
  List<Attribute> attributeList;
  List<String> selectedId = [];
  List<String> tagList = [];
  String isFav,
      isReturnable,
      isCancelable,
      isPurchased,
      availability,
      madein,
      indicator,
      stockType,
      cancleTill,
      total,
      banner,
      totalAllow,
      video,
      videType,
      warranty,
      gurantee;

  bool isFavLoading = false, isFromProd = false;
  int offset, totalItem, selVarient;

  List<Product> subList;
  List<Filter> filterList;

  Product(
      {this.id,
      this.name,
      this.desc,
      this.image,
      this.catName,
      this.type,
      this.otherImage,
      this.prVarientList,
      this.attributeList,
      this.isFav,
      this.isCancelable,
      this.isReturnable,
      this.isPurchased,
      this.availability,
      this.noOfRating,
      this.attrIds,
      this.selectedId,
      this.rating,
      this.isFavLoading,
      this.indicator,
      this.madein,
      this.tax,
      this.shortDescription,
      this.total,
      this.categoryId,
      this.subList,
      this.filterList,
      this.stockType,
      this.isFromProd,
      this.cancleTill,
      this.totalItem,
      this.offset,
      this.totalAllow,
      this.banner,
      this.selVarient,
      this.video,
      this.videType,
      this.tagList,
      this.warranty,
      this.gurantee});

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Product_Varient> varientList = (json[PRODUCT_VARIENT] as List)
        .map((data) => new Product_Varient.fromJson(data))
        .toList();

    List<Attribute> attList = (json[ATTRIBUTES] as List)
        .map((data) => new Attribute.fromJson(data))
        .toList();

    var flist = (json[FILTERS] as List);
    List<Filter> filterList = [];
    if (flist == null || flist.isEmpty)
      filterList = [];
    else
      filterList = flist.map((data) => new Filter.fromJson(data)).toList();

    List<String> other_image = List<String>.from(json[OTHER_IMAGE]);
    List<String> selected = [];

    List<String> tags = List<String>.from(json[TAG]);
    print("gurantee**prod*${json[GAURANTEE]}");
    return new Product(
        id: json[ID],
        name: json[NAME],
        desc: json[DESC],
        image: json[IMAGE],
        catName: json[CAT_NAME],
        rating: json[RATING],
        noOfRating: json[NO_OF_RATE],
        type: json[TYPE],
        isFav: json[FAV].toString(),
        isCancelable: json[ISCANCLEABLE],
        availability: json[AVAILABILITY].toString(),
        isPurchased: json[ISPURCHASED].toString(),
        isReturnable: json[ISRETURNABLE],
        otherImage: other_image,
        prVarientList: varientList,
        attributeList: attList,
        filterList: filterList,
        isFavLoading: false,
        selVarient: 0,
        attrIds: json[ATTR_VALUE],
        madein: json[MADEIN],
        shortDescription: json[SHORT],
        indicator: json[INDICATOR].toString(),
        stockType: json[STOCKTYPE].toString(),
        tax: json[TAX_PER],
        total: json[TOTAL],
        categoryId: json[CATID],
        selectedId: selected,
        totalAllow: json[TOTALALOOW],
        cancleTill: json[CANCLE_TILL],
        video: json[VIDEO],
        videType: json[VIDEO_TYPE],
        tagList: tags,
        warranty: json[WARRANTY],
        gurantee: json[GAURANTEE]);
  }

  factory Product.fromCat(Map<String, dynamic> parsedJson) {
    return new Product(
      id: parsedJson[ID],
      name: parsedJson[NAME],
      image: parsedJson[IMAGE],
      banner: parsedJson[BANNER],
      isFromProd: false,
      offset: 0,
      totalItem: 0,
      tax: parsedJson[TAX],
      subList: createSubList(parsedJson["children"]),
    );
  }

  static List<Product> createSubList(List parsedJson) {
    if (parsedJson == null || parsedJson.isEmpty) return null;

    return parsedJson.map((data) => new Product.fromCat(data)).toList();
  }
}

class Product_Varient {
  String id,
      productId,
      attribute_value_ids,
      price,
      disPrice,
      type,
      attr_name,
      varient_value,
      availability,
      cartCount;
  List<String> images;

  Product_Varient(
      {this.id,
      this.productId,
      this.attr_name,
      this.varient_value,
      this.price,
      this.disPrice,
      this.attribute_value_ids,
      this.availability,
      this.cartCount,
      this.images});

  factory Product_Varient.fromJson(Map<String, dynamic> json) {
    List<String> images = List<String>.from(json[IMAGES]);

    return new Product_Varient(
        id: json[ID],
        attribute_value_ids: json[ATTRIBUTE_VALUE_ID],
        productId: json[PRODUCT_ID],
        attr_name: json[ATTR_NAME],
        varient_value: json[VARIENT_VALUE],
        disPrice: json[DIS_PRICE],
        price: json[PRICE],
        availability: json[AVAILABILITY].toString(),
        cartCount: json[CART_COUNT],
        images: images);
  }
}

class Attribute {
  String id, value, name;

  Attribute({this.id, this.value, this.name});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return new Attribute(
      id: json[IDS],
      name: json[NAME],
      value: json[VALUE],
    );
  }
}

class Filter {
  String attributeValues, attributeValId, name;

  Filter({this.attributeValues, this.attributeValId, this.name});

  factory Filter.fromJson(Map<String, dynamic> json) {
    return new Filter(
      attributeValId: json[ATT_VAL_ID],
      name: json[NAME],
      attributeValues: json[ATT_VAL],
    );
  }
}
