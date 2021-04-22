import 'package:giftty/Helper/String.dart';
import 'package:intl/intl.dart';

// ignore: camel_case_types
class Notification_Model {
  // ignore: non_constant_identifier_names
  String id, title, desc, img, type_id, date;

  Notification_Model(
      // ignore: non_constant_identifier_names
      {this.id, this.title, this.desc, this.img, this.type_id, this.date});

  factory Notification_Model.fromJson(Map<String, dynamic> json) {
    String date = json[DATE];

    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    return new Notification_Model(
        id: json[ID],
        title: json[TITLE],
        desc: json[MESSAGE],
        img: json[IMAGE],
        type_id: json[TYPE_ID],
        date: date);
  }
}