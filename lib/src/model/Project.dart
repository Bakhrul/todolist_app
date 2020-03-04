import 'dart:ui';

class Project{
  int id;
  String title;
  String start;
  String end;
  String percent;
  int membertotal;
  List listMember;
  Color colored;
  String status;

  Project({this.id,this.title, this.start, this.end,this.colored, this.percent, this.membertotal, this.listMember,this.status});
}
