// To parse this JSON data, do
//
//     final todo = todoFromJson(jsonString);

import 'dart:convert';

List<Todo> todoFromJson(String str) => List<Todo>.from(json.decode(str).map((x) => Todo.fromJson(x)));

String todoToJson(List<Todo> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Todo {
    int id;
    String title;
    String start;
    String end;
    dynamic status;
    int category;
    int progress;

    Todo({
        this.id,
        this.title,
        this.start,
        this.end,
        this.status,
        this.category,
        this.progress
    });

    factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json["id"],
        title: json["title"],
        start: json["start"],
        end: json["end"],
        status: json["status"],
        category: json["category"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "start": start,
        "end": end,
        "status": status,
        "category": category,
    };
}
