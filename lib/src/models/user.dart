// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
    int id;
    String name;
    String email;
    String access;
    int todo;
    int owner;
    int idaccess;
    String image;

    User({
        this.id,
        this.name,
        this.email,
        this.access,
        this.todo,
        this.owner,
        this.idaccess,
        this.image,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
    };
}
