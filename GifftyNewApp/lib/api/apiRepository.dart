
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html_to_pdf/generated/i18n.dart';
import 'package:giftty/Helper/Constant.dart';
import 'package:giftty/Helper/String.dart';
import 'package:giftty/Helper/Session.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:giftty/Model/models.dart';
import 'package:giftty/Home.dart';
import 'package:flutter/widgets.dart';

abstract class ApiRepository {
  Future<List<Product>> getCat();
  Future<List<Model>> getSlider();
  Future<List<Section_Model>> getSection();
  Future<List<Model>> getOfferImages();
  Future<List<Notification_Model>> getNotification();
  Future<List<Section_Model>> getFav();
  Future<List<Product>> getProductDetail({String categoryId,String limit,String offset,String id,String isSimilar});
  Future<Section_Model> deleteFav({String id});
  Future<dynamic> addToCart({String userid, String productVarientId, String qty,int index});
  Future<dynamic> setFav({String uId,String prodId});
  Future<List<Section_Model>> removingfromFav({String userid,String productId,int index});
  removeFromCart({int index,String productVarientId, String userid, String qty});
  Future<Null> getProduct({String categoryId,String sort,String orderBy,String limit,String offset,String topRated});
}

class Api implements ApiRepository {
  List<Product> catList = [];
  List<Model> homeSliderList = [];
  List<Widget> pages = [];
  List<Model> offerImages = [];
  List<Notification_Model> notiList = [];
  List<Section_Model> favList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool isLoading = true;
  List<Notification_Model> tempList = [];
  List<Section_Model> temList = [];
  bool isNetworkAvail = true;
  bool isFavLoading = true;
  List<Product> productList = [];
  bool _isNetworkAvail = true;

  @override

  // ignore: missing_return
  Future<List<Product>> getCat() async {
    try {
      var parameter = {
        CAT_FILTER: "false",
      };
      http.Response response =
      await http.post(getCatApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        // String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          catList =
              (data as List).map((data) => new Product.fromCat(data)).toList();
        } else {
          print('somr njcvbnjc');
        }
        print(catList[0].name);
        return catList;
      }
    } on TimeoutException catch (_) {
      print('somr njcvbnjc');
    }
  }

  // ignore: missing_return
  Future<List<Model>> getSlider() async {
    try {
      http.Response response = await http.post(getSliderApi, headers: headers)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        // String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          homeSliderList =
              (data as List).map((data) => new Model.fromSlider(data)).toList();

          // pages = homeSliderList.map((slider) {
          //   return HomePage(updateHome,categoryBloc,sliderBloc)._buildImagePageItem(slider);
          // }).toList();
        } else {
          print('somr njcvbnjc');
        }
        print('slider data ${homeSliderList.length}');
        return homeSliderList;
      }
    } on TimeoutException catch (_) {

    }
  }

  // ignore: missing_return
  Future<List<Section_Model>> getSection() async {
    try {
      var parameter = {PRODUCT_LIMIT: "4", PRODUCT_OFFSET: "0"};
      if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;
      log(CUR_USERID);
      http.Response response =
      await http.post(getSectionApi, body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        // String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          sectionList =
              (data as List)
                  .map((data) => new Section_Model.fromJson(data))
                  .toList();
        } else {
          print('somr njcvbnjc');
        }
        print(sectionList[0].title);
        return sectionList;
      }
    } on TimeoutException catch (_) {
      print('somr njcvbnjc');
    }
  }

  // ignore: missing_return
  Future<List<Model>> getOfferImages() async {
    try {
      http.Response response = await http.post(
          getOfferImageApi, headers: headers)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          offerImages.clear();
          offerImages =
              (data as List).map((data) => new Model.fromSlider(data)).toList();
        } else {
          print('somr njcvbnjc$msg');
        }
        print(offerImages[0].name);
        return offerImages;
      }
    } on TimeoutException catch (_) {
      print('somr njcvbnjc');
    }
  }

  // ignore: missing_return
  Future<List<Notification_Model>> getNotification() async {
    try {
      var parameter = {
        LIMIT: perPage.toString(),
        OFFSET: offset.toString(),
      };

      http.Response response =
      await http.post(getNotificationApi, headers: headers, body: parameter)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          total = int.parse(getdata["total"]);

          if ((offset) < total) {
            tempList.clear();
            var data = getdata["data"];
            tempList = (data as List)
                .map((data) => new Notification_Model.fromJson(data))
                .toList();

            notiList.addAll(tempList);

            offset = offset + perPage;
          }
        } else {
          print('somr njcvbnjc$msg');
        }
        print(',,,,,,,,,,,,,,,,,,,,${notiList[0].title}');
        return notiList;
      }
    } on TimeoutException catch (_) {
      print('somr njcvbnjc');
    }
  }

  // ignore: missing_return
  Future<List<Section_Model>> getFav() async {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        print('66666666788888888776666666 $parameter');
        http.Response response =
        await http.post(getFavApi, body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              temList.clear();
              var data = getdata["data"];
              temList = (data as List)
                  .map((data) => new Section_Model.fromFav(data))
                  .toList();
              if (offset == 0) favList.clear();
              favList.addAll(temList);

              offset = offset + perPage;
            }
          } else {
            if (msg != 'No Favourite(s) Product Are Added')
            msg = 'no favorites';
          }
          print(',,,,,,,,,fav,,,,,,,,,,,${favList[0].id}');
          return favList;
        }
      }
        on TimeoutException catch (_) {
        print('somr njcvbnjc');
      }
  }

  // ignore: missing_return
  Future<List<Product>> getProductDetail({String categoryId,String limit,String offset,String id,String isSimilar}) async{
    print('666666666666666 666 666 6666 66666 6666 6666');
    print('6666666666$categoryId,$limit,$offset,$id,$isSimilar,6666');
    try {
      var parameter = {
        CATID: categoryId,
        LIMIT: limit,
        OFFSET: offset,
        ID: id,
        IS_SIMILAR: isSimilar
      };
      print('666666667 776666666 $parameter');
      if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

      http.Response response =
      await http.post(getProductApi, headers: headers, body: parameter)
          .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        print('headers........$headers');
print("iuivd,,,,,,,,,,,getdate,,,,,,,,${response.body}");
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          List mainlist = getdata['data'];

          if (mainlist.length != 0) {
            List<Product> items = new List<Product>();
            List<Product> allitems = new List<Product>();

            items.addAll(mainlist
                .map((data) => new Product.fromJson(data))
                .toList());

            allitems.addAll(items);

            for (Product item in items) {
              productList
                  .where((i) => i.id == item.id)
                  .map((obj) {
                allitems.remove(item);
                return obj;
              }).toList();
            }
            productList.addAll(allitems);
          }
        } else {
          print('error');
        }
        print(',,,,,,,,,pro,,,,,$msg,,,,,,${productList[0].id}');
        return productList;
      }
    }
      on TimeoutException catch (_) {
        print('time out error');
      }
  }

  Future<Section_Model> deleteFav({String id}) async {
    var parameter = {
      USER_ID: CUR_USERID,
      PRODUCT_ID: id,
    };
    http.Response response =
        await http.post(removeFavApi, body: parameter, headers: headers)
      .timeout(Duration(seconds: timeOut));
    var getData = json.decode(response.body);
    return getData;
  }

  @override
  Future<dynamic> addToCart({String userid, String productVarientId, String qty,int index}) async {
    try {
        var parameter = {
          PRODUCT_VARIENT_ID: productVarientId,
          USER_ID: userid,
          QTY: qty
        };

        http.Response response =
            await http.post(manageCartApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            CUR_CART_COUNT = data['cart_count'];
            favList[index].productList[0].prVarientList[0].cartCount =
                qty.toString();

            // widget.update();
          } else {
           print(msg);
          }}
      }
      on TimeoutException catch (_) {
      }
    // ignore: todo
    // TODO: implement addToCart
    throw UnimplementedError();
  }


  @override


  @override
  Future<List<Section_Model>> removingfromFav({String userid, String productId, int index}) async {
     try {
        var parameter = {
          USER_ID: userid,
          PRODUCT_ID: productId,
        };
        print('userid:$CUR_USERID,productid: $productId');
        http.Response response =
            await http.post(removeFavApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          favList.removeWhere((item) =>
              item.productList[0].prVarientList[0].id ==
              favList[index].productList[0].prVarientList[0].id);
        } else {
          print('gciujd$msg');
        }
      } on TimeoutException catch (_) {
        print(_.toString());
      }
    // ignore: todo
    // TODO: implement removingfromFav
    throw UnimplementedError();
  }

  @override
removeFromCart({int index,String productVarientId, String userid, String qty}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null)
        try {
          // if (mounted)
          //   setState(() {
          //     _isProgress = true;
          //   });

          var parameter = {
            PRODUCT_VARIENT_ID: productVarientId,
            USER_ID: userid,
            QTY: qty,
          };
          print("remove****$parameter");

          http.Response response =
              await http.post(manageCartApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));
          print("remove****${response.body.toString()}");
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          // ignore: unused_local_variable
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            String qty = data['total_quantity'];
            CUR_CART_COUNT = data['cart_count'];

            productList[index]
                .prVarientList[productList[index].selVarient]
                .cartCount = qty.toString();
          } else {
            // setSnackbar(msg);
          }
          // if (mounted)
          //   setState(() {
          //     _isProgress = false;
          //   });
          // if (widget.updateHome != null) widget.updateHome();
        } on TimeoutException catch (_) {
          // setSnackbar(getTranslated(context, 'somethingMSg'));
          // if (mounted)
          //   setState(() {
          //     _isProgress = false;
          //   });
        }
      else {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => Login()),
        // );
      }
    } else {
      // if (mounted)
      //   setState(() {
      //     _isNetworkAvail = false;
      //   });
    }
  }

////////////////// 19.4.21

  Future<dynamic> setFav({String uId,String prodId}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: uId, PRODUCT_ID: prodId};
        print('.........setfav    userid:$CUR_USERID,productid: $prodId');
        http.Response response =
            await http.post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        
        if (!error) {
          print(getdata["data"]);
          print(msg);
          return response;
        } 
        print(response);
      } on TimeoutException catch (_) {
      }
      
    } else {
    }
  }
  @override
  Future<Null> getProduct({String categoryId, String sort, String orderBy, String limit, String offset, String topRated}) {
    
    throw UnimplementedError();
  }

}




