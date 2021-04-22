import 'package:giftty/Helper/String.dart';
// import 'package:intl/intl.dart';

// ignore: camel_case_types
class Faqs_Model {
  String id, question,answer,status;

  Faqs_Model(
      {this.id, this.question, this.answer, this.status});

  factory Faqs_Model.fromJson(Map<String, dynamic> json) {

    return new Faqs_Model(
        id: json[ID],
        question: json[QUESTION],
        answer: json[ANSWER],
        status: json[STATUS]);
  }
}
