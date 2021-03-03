import 'package:localstorage/localstorage.dart';

import '../../common/constants.dart';

class Address {
  String firstName;
  String lastName;
  String email;
  String street;
  String apartment;
  String block;
  String city;
  String state;
  String country;
  String phoneNumber;
  String zipCode;
  String mapUrl;

  Address({
    this.firstName,
    this.lastName,
    this.email,
    this.street,
    this.apartment,
    this.block,
    this.city,
    this.state,
    this.country,
    this.phoneNumber,
    this.zipCode,
    this.mapUrl,
  });

  Address.fromJson(Map<String, dynamic> parsedJson) {
    firstName = parsedJson["first_name"];
    lastName = parsedJson["last_name"];
    apartment = parsedJson["company"];
    street = parsedJson["address_1"];
    block = parsedJson["address_2"];
    city = parsedJson["city"];
    state = parsedJson["state"];
    country = parsedJson["country"];
    email = parsedJson["email"];
    final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
    if (alphanumeric.hasMatch(firstName)) {
      phoneNumber = firstName;
    }
    //phoneNumber = parsedJson["phone"];
    zipCode = parsedJson["postcode"];
  }

  Address.fromMagentoJson(Map<String, dynamic> parsedJson) {
    firstName = parsedJson["firstname"];
    lastName = parsedJson["lastname"];
    if(parsedJson["street"] != null){
      List streets = List.from(parsedJson["street"]);
      street = streets.isNotEmpty ? streets[0] : "";
      block = streets.length > 1 ? streets[1] : "";
    }

    city = parsedJson["city"];
    state = parsedJson["region"];
    country = parsedJson["country_id"];
    email = parsedJson["email"];
    phoneNumber = parsedJson["telephone"];
    zipCode = parsedJson["postcode"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> address = {
      "first_name": firstName,
      "last_name": lastName,
      "address_1": street ?? '',
      "address_2": block ?? '',
      "company": apartment ?? '',
      "city": city,
      "state": state,
      "country": country,
      "phone": phoneNumber,
      "postcode": zipCode,
      "mapUrl": mapUrl,
    };
    if(email != null && email.isNotEmpty){
      address["email"] = email;
    }
    return address;
  }

  Address.fromLocalJson(Map<String, dynamic> json) {
    try {
      firstName = json['first_name'];
      lastName = json['last_name'];
      street = json['address_1'];
      block = json['address_2'];
      apartment = json['company'];
      city = json['city'];
      state = json['state'];
      country = json['country'];
      email = json['email'];
      phoneNumber = json['phone'];
      zipCode = json['postcode'];
      mapUrl = json['mapUrl'];
    } catch (e) {
      printLog(e.toString());
    }
  }

  Map<String, dynamic> toMagentoJson() {
    return {
      "address": {
        "region": state,
        "country_id": country,
        "region_id": state,
        "street": [
          street,
          '$apartment${(block?.isEmpty ?? true) ? '' : ' - $block'}',
        ],
        "postcode": zipCode,
        "city": city,
        "firstname": firstName,
        "lastname": lastName,
        "email": email,
        "telephone": phoneNumber,
        "same_as_billing": 1
      }
    };
  }

  Map<String, dynamic> toOpencartJson() {
    return {
      "zone_id": state,
      "country_id": country,
      "address_1": street ?? '',
      "address_2": block ?? '',
      "company": apartment ?? '',
      "postcode": zipCode,
      "city": city,
      "firstname": firstName,
      "lastname": lastName,
      "email": email,
      "telephone": phoneNumber
    };
  }

  bool isValid() {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        street.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        country.isNotEmpty &&
        phoneNumber.isNotEmpty;
  }

  Map<String, String> toJsonEncodable() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "address_1": street ?? '',
      "address_2": block ?? '',
      "company": apartment ?? '',
      "city": city,
      "state": state,
      "country": country,
      "email": email,
      "phone": phoneNumber,
      "postcode": zipCode
    };
  }

  Future<void> saveToLocal() async {
    final LocalStorage storage = LocalStorage("address");
    try {
      final ready = await storage.ready;
      if (ready) {
        await storage.setItem('', toJson());
      }
    } catch (err) {
      printLog(err);
    }
  }

  Address.fromShopifyJson(Map<String, dynamic> json) {
    try {
      firstName = json['firstName'];
      lastName = json['lastName'];
      street = json['address1'];
      block = json['address2'];
      apartment = json['company'];
      city = json['city'];
      state = json['pronvice'];
      country = json['country'];
      email = json['email'];
      phoneNumber = json['phone'];
      zipCode = json['zip'];
      mapUrl = json['mapUrl'];
    } catch (e) {
      printLog(e.toString());
    }
  }

  Map<String, dynamic> toShopifyJson() {
    return {
      "address": {
        "province": state,
        "country": country,
        "address1": street,
        "address2": block,
        "company": apartment,
        "zip": zipCode,
        "city": city,
        "firstName": firstName,
        "lastName": lastName,
        "phone": phoneNumber,
      }
    };
  }

  Address.fromOpencartOrderJson(Map<String, dynamic> json) {
    try {
      firstName = json['shipping_firstname'];
      lastName = json['shipping_lastname'];
      street = json['shipping_address_1'];
      block = json['shipping_address_2'];
      apartment = json['shipping_company'];
      city = json['shipping_city'];
      state = json['shipping_zone'];
      country = json['shipping_country'];
      email = json['email'];
      phoneNumber = json['telephone'];
      zipCode = json['shipping_postcode'];
    } catch (e) {
      printLog(e.toString());
    }
  }

  @override
  String toString() {
    return street + country + city;
  }
}

class ListAddress {
  List<Address> list = [];

  toJsonEncodable() {
    return list.map((item) {
      return item.toJsonEncodable();
    }).toList();
  }
}