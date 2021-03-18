  // Future<void> getCat() async {
  //   try {
  //     var parameter = {
  //       CAT_FILTER: "false",
  //     };
  //     Response response =
  //         await post(getCatApi, body: parameter, headers: headers)
  //             .timeout(Duration(seconds: timeOut));
  //     if (response.statusCode == 200) {
  //       var getdata = json.decode(response.body);

  //       bool error = getdata["error"];
  //       String msg = getdata["message"];
  //       if (!error) {
  //         var data = getdata["data"];

  //         catList =
  //             (data as List).map((data) => new Product.fromCat(data)).toList();
  //       } else {
  //         setSnackbar(msg);
  //       }
  //     }
  //     if (mounted) if (mounted)
  //       setState(() {
  //         _isCatLoading = false;
  //       });
  //   } on TimeoutException catch (_) {
  //     setSnackbar(getTranslated(context, 'somethingMSg'));
  //     if (mounted) if (mounted)
  //       setState(() {
  //         _isCatLoading = false;
  //       });
  //   }
  // }


// import 'package:giftty/api/httpmanager.dart';
// import 'package:giftty/model/api_result_model.dart';
// import 'package:giftty/model/banner_page_model.dart';
// import 'package:giftty/utils/utils.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:giftty/Helper/Constant.dart';
import 'package:giftty/Helper/String.dart';
import 'package:giftty/Helper/Session.dart';
import 'package:giftty/Model/Section_Model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:giftty/Model/models.dart';
import 'package:giftty/Home.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract class ApiRepository {
  Future<List<Product>> getCat();
  Future<List<Model>> getSlider();
  Future<List<Section_Model>> getSection();
}

class Api implements ApiRepository {
List<Product> catList = [];
List<Model>  homeSliderList= [];
List<Widget> pages = [];
List<Section_Model> sectionList = [];
StateHomePage homepage;
int _curSlider = 0;
  @override
  // try this too...........
  //  Future<List<Product>> getCat() async {
  //     var parameter = {
  //       CAT_FILTER: "false",
  //     };
  //   var response = await http.post(getSliderApi, headers: headers);
  //   if (response.statusCode == 200) {
  //     var data = json.jsonDecode(response.body);
  //     List<Product> articles = ApiResultModel.fromJson(data).articles;
  //     return articles;
  //   } else {
  //     throw Exception();
  //   }
  // }

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
        String msg = getdata["message"];
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


   Future<List<Model>> getSlider() async {
    try {
      http.Response response =
          await http.post(getSliderApi,headers: headers)
              .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          homeSliderList =
              (data as List).map((data) => new Model.fromSlider(data)).toList();
          //      pages = homeSliderList.map((slider) {
          //   return _buildImagePageItem(slider);
          // }).toList();
        } else {
          print('somr njcvbnjc');
        }
        print(homeSliderList[0].name);
        return homeSliderList;
      }
    } on TimeoutException catch (_) {
      print('somr njcvbnjc');
    }
}



   Future<List<Section_Model>> getSection() async {
    try {
     var parameter = {PRODUCT_LIMIT: "4", PRODUCT_OFFSET: "0"};
      if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;
      http.Response response =
          await http.post(getSectionApi, body: parameter, headers: headers)
              .timeout(Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          sectionList =
              (data as List).map((data) => new Section_Model.fromJson(data)).toList();
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

}
