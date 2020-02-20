import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:todolist_app/src/model/Member.dart';
import 'package:shimmer/shimmer.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:email_validator/email_validator.dart';

enum PageMember {
  hapusMember,
  gantiStatusMember,
}

enum PageTodo {
  hapusTodo,
  gantistatusTodo,
}

class DetailProject extends StatefulWidget {
  DetailProject({Key key, this.title, this.idproject}) : super(key: key);
  final String title;
  final int idproject;
  @override
  State<StatefulWidget> createState() {
    return _DetailProjectState();
  }
}

class _DetailProjectState extends State<DetailProject>
    with SingleTickerProviderStateMixin {
  String tokenType, accessToken;
  var datepickerfirst, datepickerlast;
  bool focus;
  TextEditingController _controllerAddpeserta = TextEditingController();
  List<Todo> listTodoProject = [];
  List<Member> listMemberProject = [];
  bool isLoading, isError;
  String _urutkanvalue;
  Map<String, String> requestHeaders = Map();
  var datepickerlastTodo, datepickerfirstTodo;
  String _tanggalawalTodo, _tanggalakhirTodo;
  bool actionBackAppBar, iconButtonAppbarColor, isSendingMessage;
  TextEditingController _searchQuery = TextEditingController();
  TextEditingController _controllerNamaTodo = TextEditingController();
  TextEditingController _controllerdeskripsiTodo = TextEditingController();
  TextEditingController _tanggalawalTodoController = TextEditingController();
  TextEditingController _tanggalakhirTodoController = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  DateTime timeReplacement;
  ProgressDialog progressApiAction;
  TabController _tabController;
  @override
  void initState() {
    _tanggalawalTodo = 'kosong';
    _tanggalakhirTodo = 'kosong';
    _controllerNamaTodo.text = '';
    _controllerdeskripsiTodo.text = '';
    _tanggalawalTodoController.text = '';
    _tanggalakhirTodoController.text = '';
    _controllerAddpeserta.text = '';
    actionBackAppBar = true;
    iconButtonAppbarColor = true;
    datepickerfirstTodo = FocusNode();
    getHeaderHTTP();
    datepickerlastTodo = FocusNode();
    _tabController =
        TabController(length: 2, vsync: _DetailProjectState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    super.initState();
    listMemberProject = [];
    _urutkanvalue = null;
    isLoading = true;
    focus = false;
    timeSetToMinute();
    listTodoProject = [];
  }

  void _handleSearchEnd() {
    setState(() {
      // ignore: new_with_non_type
      actionBackAppBar = true;
      iconButtonAppbarColor = true;
      this.actionIcon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "Manajemen Project",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      );
    });
  }

  Widget appBarTitle = Text(
    "Manajemen Project",
    style: TextStyle(fontSize: 14),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void timeSetToMinute() {
    var time = DateTime.now();
    var newHour = 0;
    var newMinute = 0;
    var newSecond = 0;
    time = time.toLocal();
    timeReplacement = new DateTime(time.year, time.month, time.day, newHour,
        newMinute, newSecond, time.millisecond, time.microsecond);
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return getDataTodo();
  }

  Future<List<List>> getDataTodo() async {
    setState(() {
      listMemberProject.clear();
      listTodoProject.clear();
      listTodoProject = [];
      listMemberProject = [];
    });
    print(widget.idproject);
    setState(() {
      isLoading = true;
    });
    try {
      final getDetailProject = await http
          .post(url('api/detail_project'), headers: requestHeaders, body: {
        'project': widget.idproject.toString(),
      });

      if (getDetailProject.statusCode == 200) {
        var getDetailProjectJson = json.decode(getDetailProject.body);
        print(getDetailProjectJson);
        var todos = getDetailProjectJson['todo'];
        var members = getDetailProjectJson['member'];

        for (var i in todos) {
          Todo todo = Todo(
            id: i['tl_id'],
            title: i['tl_title'],
            desc: i['tl_desc'],
            timestart: i['tl_timestart'],
            timeend: i['tl_timeend'],
            progress: i['tl_progress'],
            status: i['tl_status'],
          );
          listTodoProject.add(todo);
        }

        for (var i in members) {
          Member member = Member(
            iduser: i['mp_user'],
            name: i['us_name'],
            email: i['us_email'],
            roleid: i['mp_role'].toString(),
            rolename: i['r_name'],
            image: i['us_image'],
          );
          listMemberProject.add(member);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getDetailProject.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
        print(getDetailProject.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      Fluttertoast.showToast(msg: "error");
      debugPrint('$e');
    }
    return null;
  }

  void _handleTabIndex() {
    setState(() {});
  }

  void _tambahmember() async {
    await progressApiAction.show();
    try {
      final addadminevent = await http
          .post(url('api/add_member_project'), headers: requestHeaders, body: {
        'member': _controllerAddpeserta.text,
        'status': _urutkanvalue,
        'project': widget.idproject.toString(),
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          setState(() {
            _controllerAddpeserta.text = '';
            _urutkanvalue = null;
          });
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(msg: "Berhasil !");
          getDataTodo();
        } else if (addpesertaJson['status'] == 'user tidak ada') {
          setState(() {
            _controllerAddpeserta.text = '';
            _urutkanvalue = null;
          });
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(
              msg: "Email Ini Belum Terdaftar Sebagai Akun Pengguna !");
        } else if (addpesertaJson['status'] == 'member sudah ada') {
          setState(() {
            _controllerAddpeserta.text = '';
            _urutkanvalue = null;
          });
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          String roleName = addpesertaJson['role'];
          Fluttertoast.showToast(
              msg: "Akun Ini Sudah Terdaftar Sebagai $roleName");
        }
      } else {
        setState(() {
          _controllerAddpeserta.text = '';
          _urutkanvalue = null;
        });
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      setState(() {
        _controllerAddpeserta.text = '';
        _urutkanvalue = null;
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        _controllerAddpeserta.text = '';
        _urutkanvalue = null;
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  void _tambahtodo() async {
    await progressApiAction.show();
    try {
      final tambahtodoProject = await http
          .post(url('api/add_todo_project'), headers: requestHeaders, body: {
        'nama_todo': _controllerNamaTodo.text,
        'tanggal_awal': _tanggalawalTodo == 'kosong'
            ? null
            : DateFormat('dd-MM-y HH:mm:ss')
                .format(DateTime.parse(_tanggalawalTodo)),
        'tanggal_akhir': _tanggalakhirTodo == 'kosong'
            ? null
            : DateFormat('dd-MM-y HH:mm:ss')
                .format(DateTime.parse(_tanggalakhirTodo)),
        'deskripsi': _controllerdeskripsiTodo.text,
        'project': widget.idproject.toString(),
      });

      if (tambahtodoProject.statusCode == 200) {
        var tambahtodoProjectJson = json.decode(tambahtodoProject.body);
        if (tambahtodoProjectJson['status'] == 'success') {
          setState(() {
            _controllerNamaTodo.text = '';
            _controllerdeskripsiTodo.text = '';
            _tanggalawalTodoController.text = '';
            _tanggalakhirTodoController.text = '';
            _tanggalawalTodo = 'kosong';
            _tanggalakhirTodo = 'kosong';
          });
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(msg: "Berhasil !");
          getDataTodo();
        }
      } else {
        setState(() {
          _controllerNamaTodo.text = '';
          _controllerdeskripsiTodo.text = '';
          _tanggalawalTodoController.text = '';
          _tanggalakhirTodoController.text = '';
          _tanggalawalTodo = 'kosong';
          _tanggalakhirTodo = 'kosong';
        });
        print(tambahtodoProject.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      setState(() {
        _controllerNamaTodo.text = '';
        _controllerdeskripsiTodo.text = '';
        _tanggalawalTodoController.text = '';
        _tanggalakhirTodoController.text = '';
        _tanggalawalTodo = 'kosong';
        _tanggalakhirTodo = 'kosong';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        _controllerNamaTodo.text = '';
        _controllerdeskripsiTodo.text = '';
        _tanggalawalTodoController.text = '';
        _tanggalakhirTodoController.text = '';
        _tanggalawalTodo = 'kosong';
        _tanggalakhirTodo = 'kosong';
      });
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  void hapusMember(idmember) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text('Peringatan!'),
              content: Text('Apakah Anda Ingin Menghapus Secara Permanen?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Tidak'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  textColor: Colors.green,
                  child: Text('Ya'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await progressApiAction.show();
                    try {
                      final deleteMemberProject = await http.post(
                          url('api/delete_member_project'),
                          headers: requestHeaders,
                          body: {
                            'project': widget.idproject.toString(),
                            'member': idmember,
                          });
                      print(deleteMemberProject.body);
                      if (deleteMemberProject.statusCode == 200) {
                        var deletePesertaEventJson =
                            json.decode(deleteMemberProject.body);
                        if (deletePesertaEventJson['status'] == 'success') {
                          Fluttertoast.showToast(msg: "Berhasil");
                          progressApiAction.hide().then((isHidden) {
                            print(isHidden);
                          });
                          getDataTodo();
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: "Gagal, Silahkan Coba Kembali");
                        print(deleteMemberProject.body);
                        progressApiAction.hide().then((isHidden) {
                          print(isHidden);
                        });
                      }
                    } on TimeoutException catch (_) {
                      Fluttertoast.showToast(msg: "Timed out, Try again");
                      progressApiAction.hide().then((isHidden) {
                        print(isHidden);
                      });
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: "Gagal, Silahkan Coba Kembali");
                      progressApiAction.hide().then((isHidden) {
                        print(isHidden);
                      });
                      print(e);
                    }
                  },
                )
              ],
            ));
  }

  void hapusTodo(idtodo) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text('Peringatan!'),
              content: Text('Apakah Anda Ingin Menghapus Secara Permanen?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Tidak'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  textColor: Colors.green,
                  child: Text('Ya'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await progressApiAction.show();
                    try {
                      final deleteMemberProject = await http.post(
                          url('api/delete_todo_project'),
                          headers: requestHeaders,
                          body: {
                            'project': widget.idproject.toString(),
                            'todolist': idtodo,
                          });
                      print(deleteMemberProject.body);
                      if (deleteMemberProject.statusCode == 200) {
                        var deletePesertaEventJson =
                            json.decode(deleteMemberProject.body);
                        if (deletePesertaEventJson['status'] == 'success') {
                          Fluttertoast.showToast(msg: "Berhasil");
                          progressApiAction.hide().then((isHidden) {
                            print(isHidden);
                          });
                          getDataTodo();
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: "Gagal, Silahkan Coba Kembali");
                        print(deleteMemberProject.body);
                        progressApiAction.hide().then((isHidden) {
                          print(isHidden);
                        });
                      }
                    } on TimeoutException catch (_) {
                      Fluttertoast.showToast(msg: "Timed out, Try again");
                      progressApiAction.hide().then((isHidden) {
                        print(isHidden);
                      });
                    } catch (e) {
                      Fluttertoast.showToast(
                          msg: "Gagal, Silahkan Coba Kembali");
                      progressApiAction.hide().then((isHidden) {
                        print(isHidden);
                      });
                      print(e);
                    }
                  },
                )
              ],
            ));
  }

  void gantiStatusTodo(idtodo, role) async {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 230.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 15.0,
                left: 15.0,
                top: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: role == 'Open'
                                ? null
                                : () async {
                                    _updatestatusTodo(idtodo, 'Open');
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Open To Do",
                                style: TextStyle(color: Colors.white))))),
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: role == 'Pending'
                                ? null
                                : () async {
                                    _updatestatusTodo(idtodo, 'Pending');
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text('Pending To Do',
                                style: TextStyle(color: Colors.white))))),
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: role == 'Finish'
                                ? null
                                : () async {
                                    _updatestatusTodo(idtodo, 'Finish');
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Finish To Do",
                                style: TextStyle(color: Colors.white)))))
              ],
            ),
          );
        });
  }

  void gantiStatusMember(idmember, idrole) async {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 230.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 15.0,
                left: 15.0,
                top: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: idrole == '2'
                                ? null
                                : () async {
                                    _updatestatusMember(idmember, 2);
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Admin Project",
                                style: TextStyle(color: Colors.white))))),
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: idrole == '3'
                                ? null
                                : () async {
                                    _updatestatusMember(idmember, 3);
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Executor Project",
                                style: TextStyle(color: Colors.white))))),
                Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 15.0),
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: idrole == '4'
                                ? null
                                : () async {
                                    _updatestatusMember(idmember, 4);
                                  },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Viewer Project",
                                style: TextStyle(color: Colors.white)))))
              ],
            ),
          );
        });
  }

  void _updatestatusMember(idmember, role) async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final updatetatusMember = await http.post(
          url('api/update_status_member_project'),
          headers: requestHeaders,
          body: {
            'member': idmember,
            'project': widget.idproject.toString(),
            'role': role.toString(),
          });

      if (updatetatusMember.statusCode == 200) {
        var updatetatusMemberjson = json.decode(updatetatusMember.body);
        if (updatetatusMemberjson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(msg: "Berhasil !");
          getDataTodo();
        }
      } else {
        print(updatetatusMember.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  void _updatestatusTodo(idtodo, status) async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final updatetatusMember = await http.post(
          url('api/update_status_todo_project'),
          headers: requestHeaders,
          body: {
            'todo': idtodo.toString(),
            'status': status,
          });

      if (updatetatusMember.statusCode == 200) {
        var updatetatusMemberjson = json.decode(updatetatusMember.body);
        if (updatetatusMemberjson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(msg: "Berhasil !");
          getDataTodo();
        }
      } else {
        print(updatetatusMember.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    progressApiAction = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false, showLogs: false);
    progressApiAction.style(
        message: 'Tunggu Sebentar...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.w600));
    return Scaffold(
      backgroundColor: Color.fromRGBO(242, 242, 242, 1),
      appBar: buildBar(context),
      body: Container(
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: primaryAppBarColor,
                indicatorWeight: 2.0,
                tabs: [
                  Tab(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                          child: Text('Member',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black38)),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                          child: Text('Todo List',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black38)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 60.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  Container(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          isLoading == true
                              ? _loadingview()
                              : isError == true
                                  ? errorSystem(context)
                                  : Column(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(15.0),
                                          color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Container(
                                                margin: EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  'Tambah Member',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Divider(),
                                              Container(
                                                  alignment: Alignment.center,
                                                  height: 40.0,
                                                  margin: EdgeInsets.only(
                                                      bottom: 5.0, top: 5.0),
                                                  child: TextField(
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .center,
                                                    autofocus: focus,
                                                    controller:
                                                        _controllerAddpeserta,
                                                    decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Masukkan Email Pengguna',
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black,
                                                        )),
                                                  )),
                                              Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                margin:
                                                    EdgeInsets.only(top: 0.0),
                                                padding: EdgeInsets.only(
                                                    left: 10.0, right: 10.0),
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.black45),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                5.0))),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    isExpanded: true,
                                                    items: [
                                                      DropdownMenuItem<String>(
                                                        child: Text(
                                                          'Admin',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        value: '2',
                                                      ),
                                                      DropdownMenuItem<String>(
                                                        child: Text(
                                                          'Executor',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        value: '3',
                                                      ),
                                                      DropdownMenuItem<String>(
                                                        child: Text(
                                                          'Viewer',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        value: '4',
                                                      ),
                                                    ],
                                                    value: _urutkanvalue == null
                                                        ? null
                                                        : _urutkanvalue,
                                                    onChanged: (String value) {
                                                      setState(() {
                                                        _urutkanvalue = value;
                                                      });
                                                    },
                                                    hint: Text(
                                                      'Pilih level Member',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                  child: Container(
                                                      margin: EdgeInsets.only(
                                                          top: 10.0),
                                                      width: double.infinity,
                                                      height: 40.0,
                                                      child: RaisedButton(
                                                          onPressed: () async {
                                                            String emailValid =
                                                                _controllerAddpeserta
                                                                    .text;
                                                            final bool isValid =
                                                                EmailValidator
                                                                    .validate(
                                                                        emailValid);
                                                            print(
                                                                'Email is valid? ' +
                                                                    (isValid
                                                                        ? 'yes'
                                                                        : 'no'));
                                                            if (_controllerAddpeserta
                                                                        .text ==
                                                                    null ||
                                                                _controllerAddpeserta
                                                                        .text ==
                                                                    '') {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          "Email Tidak Boleh Kosong");
                                                            } else if (!isValid) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          "Masukkan Email Yang Valid");
                                                            } else if (_urutkanvalue ==
                                                                null) {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          "Pilih Level Member");
                                                            } else {
                                                              _tambahmember();
                                                            }
                                                          },
                                                          color:
                                                              primaryAppBarColor,
                                                          textColor:
                                                              Colors.white,
                                                          disabledColor:
                                                              Color.fromRGBO(
                                                                  254,
                                                                  86,
                                                                  14,
                                                                  0.7),
                                                          disabledTextColor:
                                                              Colors.white,
                                                          splashColor:
                                                              Colors.blueAccent,
                                                          child: Text(
                                                              "Tambahkan Member",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .white)))))
                                            ],
                                          ),
                                        ),
                                        Container(
                                            color: Colors.white,
                                            margin: EdgeInsets.only(
                                              top: 10.0,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Container(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: listMemberProject
                                                      .map(
                                                          (Member item) => Card(
                                                              elevation: 0.6,
                                                              child: ListTile(
                                                                leading:
                                                                    Container(
                                                                  width: 40.0,
                                                                  height: 40.0,
                                                                  child:
                                                                      ClipOval(
                                                                    child: FadeInImage
                                                                        .assetNetwork(
                                                                      placeholder:
                                                                          'images/loading.gif',
                                                                      image: item.image == null ||
                                                                              item.image ==
                                                                                  '' ||
                                                                              item.image ==
                                                                                  'null'
                                                                          ? url(
                                                                              'assets/images/imgavatar.png')
                                                                          : url(
                                                                              'storage/image/profile/${item.image}'),
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                ),
                                                                title: Text(
                                                                    item.name ==
                                                                                '' ||
                                                                            item.name ==
                                                                                null
                                                                        ? 'Member Tidak Diketahui'
                                                                        : item
                                                                            .name,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w500)),
                                                                subtitle:
                                                                    Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top:
                                                                          15.0),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: <
                                                                        Widget>[
                                                                      Text(
                                                                        item.rolename == '' ||
                                                                                item.rolename == null
                                                                            ? 'Status tidak diketahui'
                                                                            : item.rolename,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: Colors.green),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                trailing: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: <
                                                                      Widget>[
                                                                    PopupMenuButton<
                                                                        PageMember>(
                                                                      onSelected:
                                                                          (PageMember
                                                                              value) {
                                                                        switch (
                                                                            value) {
                                                                          case PageMember
                                                                              .hapusMember:
                                                                            hapusMember(item.iduser.toString());
                                                                            break;
                                                                          case PageMember
                                                                              .gantiStatusMember:
                                                                            gantiStatusMember(item.iduser.toString(),
                                                                                item.roleid);
                                                                            break;
                                                                          default:
                                                                            break;
                                                                        }
                                                                      },
                                                                      icon: Icon(
                                                                          Icons
                                                                              .more_vert),
                                                                      itemBuilder:
                                                                          (context) =>
                                                                              [
                                                                        PopupMenuItem(
                                                                          value:
                                                                              PageMember.gantiStatusMember,
                                                                          child:
                                                                              Text("Ganti Status"),
                                                                        ),
                                                                        PopupMenuItem(
                                                                          // value: PageEnum.deletePeserta,
                                                                          child:
                                                                              Text("Atur TodoList"),
                                                                        ),
                                                                        PopupMenuItem(
                                                                          value:
                                                                              PageMember.hapusMember,
                                                                          child:
                                                                              Text("Hapus Member"),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              )))
                                                      .toList(),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          isLoading == true
                              ? _loadingview()
                              : isError == true
                                  ? errorSystem(context)
                                  : Column(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(15.0),
                                          color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Container(
                                                margin: EdgeInsets.only(
                                                    bottom: 10.0),
                                                child: Text(
                                                  'Tambah To Do',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Divider(),
                                              Container(
                                                  height: 40.0,
                                                  alignment: Alignment.center,
                                                  margin: EdgeInsets.only(
                                                      bottom: 5.0, top: 5.0),
                                                  child: TextField(
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .center,
                                                    autofocus: focus,
                                                    controller:
                                                        _controllerNamaTodo,
                                                    decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Masukkan Nama To Do',
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black,
                                                        )),
                                                  )),
                                              Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                margin: EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: DateTimeField(
                                                  controller:
                                                      _tanggalawalTodoController,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                            top: 2,
                                                            bottom: 2,
                                                            left: 10,
                                                            right: 10),
                                                    hintText:
                                                        'Tanggal Dimulainya To Do',
                                                    hintStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black),
                                                  ),
                                                  readOnly: true,
                                                  format: format,
                                                  focusNode:
                                                      datepickerfirstTodo,
                                                  onShowPicker: (context,
                                                      currentValue) async {
                                                    final date =
                                                        await showDatePicker(
                                                            context: context,
                                                            firstDate:
                                                                DateTime.now(),
                                                            initialDate:
                                                                DateTime.now(),
                                                            lastDate:
                                                                DateTime(2100));
                                                    if (date != null) {
                                                      final time =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime: TimeOfDay
                                                            .fromDateTime(
                                                                currentValue ??
                                                                    timeReplacement),
                                                      );
                                                      return DateTimeField
                                                          .combine(date, time);
                                                    } else {
                                                      return currentValue;
                                                    }
                                                  },
                                                  onChanged: (ini) {
                                                    setState(() {
                                                      _tanggalakhirTodoController
                                                          .text = '';
                                                      _tanggalakhirTodo =
                                                          'kosong';
                                                      _tanggalawalTodo =
                                                          ini == null
                                                              ? 'kosong'
                                                              : ini.toString();
                                                    });
                                                  },
                                                ),
                                              ),
                                              Container(
                                                height: 40.0,
                                                alignment: Alignment.center,
                                                margin: EdgeInsets.only(
                                                    bottom: 5.0),
                                                child: DateTimeField(
                                                  controller:
                                                      _tanggalakhirTodoController,
                                                  decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                            top: 2,
                                                            bottom: 2,
                                                            left: 10,
                                                            right: 10),
                                                    hintText:
                                                        'Tanggal Berakhirnya To Do',
                                                    hintStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black),
                                                  ),
                                                  readOnly: true,
                                                  format: format,
                                                  focusNode: datepickerlastTodo,
                                                  onShowPicker: (context,
                                                      currentValue) async {
                                                    final date = await showDatePicker(
                                                        context: context,
                                                        firstDate:
                                                            _tanggalawalTodo ==
                                                                    'kosong'
                                                                ? DateTime.now()
                                                                : DateTime.parse(
                                                                    _tanggalawalTodo),
                                                        initialDate:
                                                            _tanggalawalTodo ==
                                                                    'kosong'
                                                                ? DateTime.now()
                                                                : DateTime.parse(
                                                                    _tanggalawalTodo),
                                                        lastDate:
                                                            DateTime(2100));
                                                    if (date != null) {
                                                      final time =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime: TimeOfDay
                                                            .fromDateTime(
                                                                currentValue ??
                                                                    timeReplacement),
                                                      );
                                                      return DateTimeField
                                                          .combine(date, time);
                                                    } else {
                                                      return currentValue;
                                                    }
                                                  },
                                                  onChanged: (ini) {
                                                    setState(() {
                                                      _tanggalakhirTodo =
                                                          ini == null
                                                              ? 'kosong'
                                                              : ini.toString();
                                                    });
                                                  },
                                                ),
                                              ),
                                              Container(
                                                  height: 100.0,
                                                  margin: EdgeInsets.only(
                                                      bottom: 5.0),
                                                  child: TextField(
                                                    maxLines: 5,
                                                    autofocus: focus,
                                                    controller:
                                                        _controllerdeskripsiTodo,
                                                    decoration: InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        hintText:
                                                            'Deskripsi To Do',
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black,
                                                        )),
                                                  )),
                                              Center(
                                                  child: Container(
                                                      margin: EdgeInsets.only(
                                                          top: 10.0),
                                                      width: double.infinity,
                                                      height: 40.0,
                                                      child: RaisedButton(
                                                          onPressed: () async {
                                                            if (_controllerNamaTodo
                                                                    .text ==
                                                                '') {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Masukkan Nama To Do');
                                                            } else if (_tanggalawalTodoController
                                                                    .text ==
                                                                '') {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Tanggal Dimulainya To Do Tidak Boleh Kosong');
                                                            } else if (_tanggalakhirTodoController
                                                                    .text ==
                                                                '') {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Tanggal Berakhirnya To Do Tidak Boleh Kosong');
                                                            } else if (_controllerdeskripsiTodo
                                                                    .text ==
                                                                '') {
                                                              Fluttertoast
                                                                  .showToast(
                                                                      msg:
                                                                          'Deskripsi To Do Tidak Boleh Kosong');
                                                            } else {
                                                              _tambahtodo();
                                                            }
                                                          },
                                                          color:
                                                              primaryAppBarColor,
                                                          textColor:
                                                              Colors.white,
                                                          disabledColor:
                                                              Color.fromRGBO(
                                                                  254,
                                                                  86,
                                                                  14,
                                                                  0.7),
                                                          disabledTextColor:
                                                              Colors.white,
                                                          splashColor:
                                                              Colors.blueAccent,
                                                          child: Text(
                                                              "Tambahkan To Do",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .white)))))
                                            ],
                                          ),
                                        ),
                                        Container(
                                            color: Colors.white,
                                            margin: EdgeInsets.only(
                                              top: 10.0,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Container(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: listTodoProject
                                                      .map((Todo item) => Card(
                                                          elevation: 0.6,
                                                          child: ListTile(
                                                            leading: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(0.0),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            100.0),
                                                                child:
                                                                    Container(
                                                                  height: 40.0,
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  width: 40.0,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .white,
                                                                        width:
                                                                            2.0),
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(100.0) //                 <--- border radius here
                                                                            ),
                                                                    color:
                                                                        primaryAppBarColor,
                                                                  ),
                                                                  child: Text(
                                                                    '${item.title[0]}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            title: Text(
                                                                item.title ==
                                                                            '' ||
                                                                        item.title ==
                                                                            null
                                                                    ? 'To Do Tidak Diketahui'
                                                                    : item
                                                                        .title,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500)),
                                                            subtitle: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      top:
                                                                          15.0),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: <
                                                                    Widget>[
                                                                  Text(
                                                                      item.status == '' ||
                                                                              item.status ==
                                                                                  null
                                                                          ? 'Status Tidak Diketahui'
                                                                          : item
                                                                              .status,
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      )),
                                                                ],
                                                              ),
                                                            ),
                                                            trailing: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <
                                                                  Widget>[
                                                                PopupMenuButton<
                                                                    PageTodo>(
                                                                  onSelected:
                                                                      (PageTodo
                                                                          value) {
                                                                    switch (
                                                                        value) {
                                                                      case PageTodo
                                                                          .hapusTodo:
                                                                        hapusTodo(item
                                                                            .id
                                                                            .toString());
                                                                        break;
                                                                      case PageTodo
                                                                          .gantistatusTodo:
                                                                        gantiStatusTodo(
                                                                            item.id,
                                                                            item.status);
                                                                        break;

                                                                      default:
                                                                        break;
                                                                    }
                                                                  },
                                                                  icon: Icon(Icons
                                                                      .more_vert),
                                                                  itemBuilder:
                                                                      (context) =>
                                                                          [
                                                                    PopupMenuItem(
                                                                      value: PageTodo
                                                                          .gantistatusTodo,
                                                                      child: Text(
                                                                          "Ganti Status To Do"),
                                                                    ),
                                                                    PopupMenuItem(
                                                                      // value: PageEnum.deletePeserta,
                                                                      child: Text(
                                                                          "Atur Member To Do"),
                                                                    ),
                                                                    PopupMenuItem(
                                                                      value: PageTodo
                                                                          .hapusTodo,
                                                                      child: Text(
                                                                          "Hapus To Do"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          )))
                                                      .toList(),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: _bottomButtons(),
    );
  }

  Widget _loadingview() {
    return Container(
        color: Colors.white,
        margin: EdgeInsets.only(
          top: 10.0,
        ),
        padding: EdgeInsets.all(15.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4, 5]
                  .map((_) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(bottom: 25.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(100.0)),
                                  ),
                                  width: 35.0,
                                  height: 35.0,
                                ),
                                Expanded(
                                  flex: 9,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(left: 15.0),
                                        width: double.infinity,
                                        height: 10.0,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        margin: EdgeInsets.only(
                                            left: 15.0, top: 15.0),
                                        width: 100.0,
                                        height: 10.0,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        )));
  }

  Widget errorSystem(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: RefreshIndicator(
        onRefresh: () => getHeaderHTTP(),
        child: Column(children: <Widget>[
          new Container(
            width: 100.0,
            height: 100.0,
            child: Image.asset("images/system-eror.png"),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 30.0,
              left: 15.0,
              right: 15.0,
            ),
            child: Center(
              child: Text(
                "Gagal memuat halaman, tekan tombol muat ulang halaman untuk refresh halaman",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 15.0, left: 15.0, right: 15.0, bottom: 15.0),
            child: SizedBox(
              width: double.infinity,
              child: RaisedButton(
                color: Colors.white,
                textColor: primaryAppBarColor,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(15.0),
                onPressed: () async {
                  getHeaderHTTP();
                },
                child: Text(
                  "Muat Ulang Halaman",
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget buildBar(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: appBarTitle,
          titleSpacing: 0.0,
          backgroundColor: primaryAppBarColor,
          automaticallyImplyLeading: actionBackAppBar,
          actions: <Widget>[
            Container(
              color: iconButtonAppbarColor == true
                  ? primaryAppBarColor
                  : Colors.white,
              child: IconButton(
                icon: actionIcon,
                onPressed: () {
                  setState(() {
                    if (this.actionIcon.icon == Icons.search) {
                      actionBackAppBar = false;
                      iconButtonAppbarColor = false;
                      this.actionIcon = new Icon(
                        Icons.close,
                        color: Colors.black87,
                      );
                      this.appBarTitle = Container(
                        height: 50.0,
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(0),
                        margin: EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: TextField(
                          autofocus: true,
                          controller: _searchQuery,
                          onChanged: (string) {
                            if (string != null || string != '') {}
                          },
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon:
                                new Icon(Icons.search, color: Colors.black87),
                            hintText: "Cari...",
                            hintStyle: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    } else {
                      _handleSearchEnd();
                    }
                  });
                },
              ),
            ),
          ],
        ));
  }
}
