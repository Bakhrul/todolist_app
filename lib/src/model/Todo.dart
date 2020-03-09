import 'dart:ui';

class Todo{
  int id;
  String title;
  String desc;
  String timestart;
  String timeend;
  String status;
  String progress;
  Color coloredProgress;
  String statuspinned;
  int allday;
  String statusProgress;
  String statusMolor;
  String statusPending;

  Todo({this.id,this.title, this.desc, this.timestart, this.timeend,
   this.status, this.progress,this.coloredProgress,this.statuspinned,
    this.allday, this.statusProgress, this.statusMolor, this.statusPending });
}
