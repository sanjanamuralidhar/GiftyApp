import 'package:giftty/Helper/String.dart';
// import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class User {
  String username,
      email,
      mobile,
      address,
      dob,
      city,
      area,
      street,
      password,
      pincode,
      // ignore: non_constant_identifier_names
      fcm_id,
      latitude,
      longitude,
      // ignore: non_constant_identifier_names
      user_id,
      name,
      deliveryCharge,
      freeAmt;

  List<String> imgList;
  String id, date, comment, rating;

  // ignore: non_constant_identifier_names
  String type, alt_mob, landmark, areaId, cityId, isDefault, state, country;

  User(
      {this.id,
      this.username,
      this.date,
      this.rating,
      this.comment,
      this.email,
      this.mobile,
      this.address,
      this.dob,
      this.city,
      this.area,
      this.street,
      this.password,
      this.pincode,
      // ignore: non_constant_identifier_names
      this.fcm_id,
      this.latitude,
      this.longitude,
      // ignore: non_constant_identifier_names
      this.user_id,
      this.name,
      this.type,
      // ignore: non_constant_identifier_names
      this.alt_mob,
      this.landmark,
      this.areaId,
      this.cityId,
      this.imgList,
      this.isDefault,
      this.state,
      this.deliveryCharge,
      this.freeAmt,
      this.country});

  factory User.forReview(Map<String, dynamic> parsedJson) {
    String date = parsedJson['data_added'];
    var allSttus = parsedJson['images'];
    List<String> item = [];

    for (String i in allSttus) item.add(i);

    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));

    return new User(
      id: parsedJson[ID],
      date: date,
      rating: parsedJson[RATING],
      comment: parsedJson[COMMENT],
      imgList: item,
      username: parsedJson[USER_NAME],
    );
  }

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    return new User(
      id: parsedJson[ID],
      username: parsedJson[USERNAME],
      email: parsedJson[EMAIL],
      mobile: parsedJson[MOBILE],
      address: parsedJson[ADDRESS],
      dob: parsedJson[DOB],
      city: parsedJson[CITY],
      area: parsedJson[AREA],
      street: parsedJson[STREET],
      password: parsedJson[PASSWORD],
      pincode: parsedJson[PINCODE],
      fcm_id: parsedJson[FCM_ID],
      latitude: parsedJson[LATITUDE],
      longitude: parsedJson[LONGITUDE],
      user_id: parsedJson[USER_ID],
      name: parsedJson[NAME],
    );
  }

  factory User.fromAddress(Map<String, dynamic> parsedJson) {
    return new User(
        id: parsedJson[ID],
        mobile: parsedJson[MOBILE],
        address: parsedJson[ADDRESS],
        alt_mob: parsedJson[ALT_MOBNO],
        cityId: parsedJson[CITY_ID],
        areaId: parsedJson[AREA_ID],
        area: parsedJson[AREA],
        city: parsedJson[CITY],
        landmark: parsedJson[LANDMARK],
        state: parsedJson[STATE],
        pincode: parsedJson[PINCODE],
        country: parsedJson[COUNTRY],
        latitude: parsedJson[LATITUDE],
        longitude: parsedJson[LONGITUDE],
        user_id: parsedJson[USER_ID],
        name: parsedJson[NAME],
        type: parsedJson[TYPE],
        deliveryCharge: parsedJson[DEL_CHARGES],
        freeAmt: parsedJson[FREE_AMT],
        isDefault: parsedJson[ISDEFAULT]);
  }
}
