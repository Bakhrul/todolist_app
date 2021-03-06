// To parse this JSON data, do
//
//     final project = projectFromJson(jsonString);

import 'dart:convert';

import 'dart:ui';

List<Project> projectFromJson(String str) => List<Project>.from(json.decode(str).map((x) => Project.fromJson(x)));

String projectToJson(List<Project> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Project {
    int id;
    String title;
    String start;
    String end;
    Color colored;
    String status;
    String progress;
    bool isProject;

    Project({
        this.id,
        this.title,
        this.start,
        this.end,
        this.colored,
        this.status,
        this.progress,
        this.isProject
    });

    factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json["id"],
        title: json["title"],
        start: json["start"],
        end: json["end"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "start": start,
        "end": end,
    };
}
