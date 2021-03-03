import 'dart:async';
import 'dart:convert' as convert;
import "dart:core";

import 'package:http/http.dart' as http;
import 'package:quiver/strings.dart' show isNotBlank;

import '../../../common/config.dart';
import '../../../models/entities/prediction.dart';
import '../../../models/index.dart' show Product, Review, User;
import '../../../models/vendor/store_model.dart';
import '../../woocommerce/services/woo_commerce.dart';
import 'dokan_api.dart';

class DokanApi with WooCommerce {
  static final DokanApi _instance = DokanApi._internal();

  factory DokanApi() => _instance;

  DokanApi._internal();

  DokanAPI dokanApi;

  @override
  void appConfig(appConfig) {
    super.appConfig(appConfig);
    dokanApi = DokanAPI(url: appConfig["url"]);
  }

  @override
  Future<User> createUser({
    String firstName,
    String lastName,
    String username,
    String password,
    String phoneNumber,
    bool isVendor = false,
  }) async {
    try {
      String niceName = firstName + " " + lastName;
      final http.Response response = await http.post(
          "$url/wp-json/api/flutter_user/sign_up/?insecure=cool&$isSecure",
          body: convert.jsonEncode({
            "user_email": username,
            "user_login": username,
            "username": username,
            "first_name": firstName,
            "last_name": lastName,
            "user_pass": password,
            "email": username,
            "user_nicename": niceName,
            "display_name": niceName,
            "phone": phoneNumber,
            "role": (isVendor ?? false) ? "seller" : "subscriber"
          }));
      final body = convert.jsonDecode(response.body);
      if (response.statusCode == 200 && body["message"] == null) {
        var cookie = body['cookie'];
        return await getUserInfo(cookie);
      } else {
        var message = body["message"];
        throw Exception(message != null ? message : "Can not create the user.");
      }
    } catch (err) {
      rethrow;
    }
  }

  @override
  Future<List<Store>> getFeaturedStores() async {
    int page = 1;
    List<Store> list = [];
    while (true) {
      try {
        var response =
            await dokanApi.getAsync("stores?page=$page&per_page=100");
        if (response.length == 0) {
          return list;
        }
        if (response is Map && isNotBlank(response["message"])) {
          throw Exception(response["message"]);
        } else {
          for (var item in response) {
            if (item['featured']) list.add(Store.fromDokanJson(item));
          }
          page++;
        }
      } catch (e) {
        return list;
      }
    }
  }

  @override
  Future<List<Product>> getProductsByStore({storeId, page}) async {
    try {
      List<Product> list = [];
      var response = await dokanApi
          .getAsync("stores/$storeId/products?page=$page&per_page=10");

      if (response is Map && isNotBlank(response["message"])) {
        throw Exception(response["message"]);
      } else {
        for (var item in response) {
          final product = Product.fromJson(item);
          product.store = Store.fromDokanJson(item["store"]);
          list.add(product);
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Review>> getReviewsStore({storeId}) async {
    try {
      List<Review> list = [];
      var response = await dokanApi.getAsync("stores/$storeId/reviews");

      if (response is Map && isNotBlank(response["message"])) {
        throw Exception(response["message"]);
      } else {
        for (var item in response) {
          list.add(Review.fromDokanJson(item));
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Store> getStoreInfo(storeId) async {
    try {
      var response = await dokanApi.getAsync("stores/$storeId");

      if (response is Map && isNotBlank(response["message"])) {
        throw Exception(response["message"]);
      } else {
        return Store.fromDokanJson(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future getJWTToken() {
    return null;
  }

  @override
  Future<List<Store>> searchStores({String keyword, int page}) async {
    try {
      List<Store> list = [];
      var endPoint = 'stores?';
      if (keyword?.isNotEmpty ?? false) {
        endPoint += 'search=$keyword';
      }

      endPoint += '&page=$page';

      var response = await dokanApi.getAsync(endPoint);

      if (response is Map && isNotBlank(response["message"])) {
        throw Exception(response["message"]);
      } else {
        for (var item in response) {
          list.add(Store.fromDokanJson(item));
        }
        return list;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Store>> getNearbyStores(Prediction prediction) async {
    List<Store> list = [];
    try {
      var response = await wcApi.getAsync(
          "flutter/get-nearby-stores?distance=${kAdvanceConfig['QueryRadiusDistance']}&latitude=${prediction.lat}&longitude=${prediction.long}");
      if (response is Map && isNotBlank(response["message"])) {
        throw Exception(response["message"]);
      } else {
        for (var item in response) {
          Store store = Store.fromDokanJson(item);
          if (store.lat != null && store.long != null) {
            list.add(store);
          }
        }
      }
      return list;
    } catch (e) {
      rethrow;
    }
  }
}
