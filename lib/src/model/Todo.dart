import 'dart:ui';

class Todo{
  int id;
  String title;
  String desc;
  String timestart;
  String timeend;
  String status;
  String progress;
  Color colored;
  String statuspinned;

  Todo({this.id,this.title, this.desc, this.timestart, this.timeend, this.status, this.progress,this.colored,this.statuspinned});
}
