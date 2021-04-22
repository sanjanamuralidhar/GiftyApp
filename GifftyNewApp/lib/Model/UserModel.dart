class UserModel {
  final String id;
  // ignore: non_constant_identifier_names
  final String first_names;
  final String surname;
  final String email;

  // ignore: non_constant_identifier_names
  UserModel({this.id, this.first_names, this.surname, this.email});

  UserModel.fromJson(Map json)
      : id = json["_id"]["\$oid"],
        first_names = json["first_names"],
        surname = json["surname"],
        email = json["email"];

  Map toJson() {
    return {
      'id': id,
      'first_names': first_names,
      'surname': surname,
      'email': email
    };
  }
}
