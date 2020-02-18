// To parse this JSON data, do
//
//     final project = projectFromJson(jsonString);

import 'dart:convert';

List<Project> projectFromJson(String str) => List<Project>.from(json.decode(str).map((x) => Project.fromJson(x)));

String projectToJson(List<Project> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Project {
    int id;
    String title;
    String start;
    DateTime end;

    Project({
        this.id,
        this.title,
        this.start,
        this.end,
    });

    factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json["id"],
        title: json["title"],
        start: json["start"],
        end: DateTime.parse(json["end"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "start": start,
        "end": end.toIso8601String(),
    };
}
