import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/model/FriendList.dart';
import 'package:todolist_app/src/pages/todolist/friend_list.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:email_validator/email_validator.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:shimmer/shimmer.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/model/category.dart';
import 'package:flutter/services.dart';
import 'package:todolist_app/src/model/TodoMember.dart';
import 'package:todolist_app/src/model/TodoAttachment.dart';
import 'choose_project.dart';
import 'delete_todolist.dart';

String tokenType, accessToken;
String categoriesID;
String categoriesName;
String friendId;
String friendName;
bool isLoading, isError;
String idProjectEditChoose;
String namaProjectEditChoose, titleEdit;
String idMemberFriend;
String emailMemberFriend;
String nameMemberFriend;

class ManajemenEditTodo extends StatefulWidget {
  ManajemenEditTodo({Key key, this.title, this.idTodo, this.platform})
      : super(key: key);
  final String title;
  final int idTodo;
  final TargetPlatform platform;
  @override
  State<StatefulWidget> createState() {
    return _ManajemenEditTodoState();
  }
}

class _ManajemenEditTodoState extends State<ManajemenEditTodo>
    with SingleTickerProviderStateMixin {
  String _dfileName;
  String fileImage;
  bool _loadingPath;
  String _urutkanvalue;
  String _alldayTipe;
  Map dataTodo, dataStatusKita;
  bool _hasValidMime;
  FileType _pickingType;
  String filename;
  ProgressDialog progressApiAction;
  TextEditingController _controllerNamaMember = TextEditingController();
  final format = DateFormat("yyyy-MM-dd HH:mm:ss");
  DateTime timeReplacement;
  TabController _tabController;
  List<ListKategori> listCategory = [];
  List<MemberTodo> listMemberTodo = [];
  List<FileTodo> listFileTodo = [];
  String titleTodo, planStartTodo, planEndTodo, categoryTodo, descTodo;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _dateStartController = TextEditingController();
  TextEditingController _dateEndController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  Map<String, String> requestHeaders = Map();

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
    return getDataEdit();
  }

  Future<List<List>> getDataEdit() async {
    setState(() {
      isLoading = true;
      listCategory.clear();
      listCategory = [];
      listMemberTodo.clear();
      listMemberTodo = [];
      listFileTodo.clear();
      listFileTodo = [];
    });
    listCategory.clear();
    listCategory = [];
    listMemberTodo.clear();
    listMemberTodo = [];
    listFileTodo.clear();
    listFileTodo = [];
    try {
      final participant = await http.get(url('api/todo/edit/${widget.idTodo}'),
          headers: requestHeaders);

      if (participant.statusCode == 200) {
        setState(() {
          listCategory.clear();
          listCategory = [];
          listMemberTodo.clear();
          listMemberTodo = [];
          listFileTodo.clear();
          listFileTodo = [];
        });
        listCategory.clear();
        listCategory = [];
        listMemberTodo.clear();
        listMemberTodo = [];
        listFileTodo.clear();
        var listParticipantToJson = json.decode(participant.body);
        Map rawTodo = listParticipantToJson['todo'];
        Map rawStatusKita = listParticipantToJson['statuskita'];
        var members = listParticipantToJson['member_todo'];
        var ducuments = listParticipantToJson['document_todo'];
        titleEdit = rawTodo['tl_title'].toString();
        for (var i in members) {
          MemberTodo member = MemberTodo(
            iduser: i['us_id'],
            name: i['us_name'],
            email: i['us_email'],
            roleid: i['tlr_role'].toString(),
            rolename: i['r_name'],
            image: i['us_image'],
          );
          listMemberTodo.add(member);
        }

        for (var i in ducuments) {
          FileTodo file = FileTodo(
            id: i['tla_id'],
            path: i['tla_path'],
          );
          listFileTodo.add(file);
        }

        setState(() {
          dataTodo = rawTodo;
          dataStatusKita = rawStatusKita;
          _titleController.text = rawTodo['tl_title'];
          _dateEndController.text = rawTodo != null
              ? rawTodo['tl_allday'].toString() == '1'
                  ? DateFormat("dd-MM-yyyy")
                      .format(DateTime.parse(rawTodo['tl_planend']))
                  : DateFormat("dd-MM-yyyy HH:mm:ss")
                      .format(DateTime.parse(rawTodo['tl_planend']))
              : rawTodo['tl_planend'];
          _dateStartController.text = rawTodo != null
              ? rawTodo['tl_allday'].toString() == '1'
                  ? DateFormat("dd-MM-yyyy")
                      .format(DateTime.parse(rawTodo['tl_planstart']))
                  : DateFormat("dd-MM-yyyy HH:mm:ss")
                      .format(DateTime.parse(rawTodo['tl_planstart']))
              : rawTodo['tl_planstart'];
          _descController.text = rawTodo['tl_desc'];
          categoriesName = rawTodo['c_name'];
          categoriesID = rawTodo['tl_category'].toString();
          _alldayTipe = rawTodo['tl_allday'].toString();
        });
        return getDataCategory();
      } else if (participant.statusCode == 401) {
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
        print(participant.body);
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
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> getDataCategory() async {
    try {
      final participant =
          await http.get(url('api/category'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;
        print(participants);
        for (var i in participants) {
          ListKategori participant = ListKategori(
            id: i['id'].toString(),
            name: i['name'],
          );
          listCategory.add(participant);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (participant.statusCode == 401) {
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
        print(participant.body);
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
      debugPrint('$e');
    }
    return null;
  }

  @override
  void initState() {
    getHeaderHTTP();
    _tabController = TabController(
        length: 3, vsync: _ManajemenEditTodoState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    _alldayTipe = null;
    super.initState();
    _loadingPath = false;
    isLoading = true;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  void tambahkanMember() async {
    await progressApiAction.show();
    try {
      final addMemberTodo = await http.post(url('api/todo_edit/tambah_member'),
          headers: requestHeaders,
          body: {
            'todolist': widget.idTodo.toString(),
            'member': emailMemberFriend == null
                ? _controllerNamaMember.text
                : emailMemberFriend,
            'role': _urutkanvalue,
          });
      print(addMemberTodo.body);
      if (addMemberTodo.statusCode == 200) {
        var addMemberTodoJson = json.decode(addMemberTodo.body);
        if (addMemberTodoJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          getHeaderHTTP();
          setState(() {
            _controllerNamaMember.text = '';
            _urutkanvalue = null;
            emailMemberFriend = null;
            nameMemberFriend = null;
          });
        } else if (addMemberTodoJson['status'] == 'email belum terdaftar') {
          Fluttertoast.showToast(msg: "Email Ini Belum Memiliki Akun Pengguna");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          setState(() {
            _controllerNamaMember.text = '';
            _urutkanvalue = null;
            emailMemberFriend = null;
            nameMemberFriend = null;
          });
        } else if (addMemberTodoJson['status'] == 'member sudah terdaftar') {
          Fluttertoast.showToast(msg: "Member Ini Sudah Terdaftar Pada ToDo");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          setState(() {
            _controllerNamaMember.text = '';
            _urutkanvalue = null;
            emailMemberFriend = null;
            nameMemberFriend = null;
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        print(addMemberTodo.body);
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
        setState(() {
          _controllerNamaMember.text = '';
          _urutkanvalue = null;
          emailMemberFriend = null;
          nameMemberFriend = null;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      setState(() {
        _controllerNamaMember.text = '';
        _urutkanvalue = null;
        emailMemberFriend = null;
        nameMemberFriend = null;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      setState(() {
        _controllerNamaMember.text = '';
        _urutkanvalue = null;
        emailMemberFriend = null;
        nameMemberFriend = null;
      });
      print(e);
    }
  }

  void deleteMember(idMember) async {
    await progressApiAction.show();
    try {
      final addMemberTodo = await http.post(url('api/todo_edit/delete_member'),
          headers: requestHeaders,
          body: {
            'todolist': widget.idTodo.toString(),
            'member': idMember.toString(),
          });
      print(addMemberTodo.body);
      if (addMemberTodo.statusCode == 200) {
        var addMemberTodoJson = json.decode(addMemberTodo.body);
        if (addMemberTodoJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          getHeaderHTTP();
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        print(addMemberTodo.body);
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
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      print(e);
    }
  }

  void _openFileExplorer() async {
    if (_pickingType != FileType.CUSTOM || _hasValidMime) {
      setState(() => _loadingPath = true);
      try {
        File file = await FilePicker.getFile(type: FileType.ANY);
        setState(() {
          _dfileName = file.toString();
          fileImage = base64Encode(file.readAsBytesSync());
          _loadingPath = false;
          filename = file.toString().split('/').last;
        });
      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }
      if (!mounted) return;
    }
  }

  void tambahkanFile() async {
    await progressApiAction.show();
    try {
      dynamic body = {
        'todolist': widget.idTodo.toString(),
        'file64': fileImage.toString(),
        'pathname': _dfileName.toString(),
        'filename': filename.toString(),
      };
      print(body);
      final tambahfile = await http.post(url('api/todo_edit/tambah_file'),
          headers: requestHeaders, body: body);
      if (tambahfile.statusCode == 200) {
        var tambahFileJson = json.decode(tambahfile.body);
        if (tambahFileJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: 'success');
          getHeaderHTTP();
        }
      } else {
        print(tambahfile.body);
        progressApiAction.hide().then((isHidden) {});
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {});
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      print(e.toString());
      progressApiAction.hide().then((isHidden) {});
      Fluttertoast.showToast(msg: "Gagal Silahkan Coba Kembali");
    }
  }

  void deleteFile(idFile) async {
    print(idFile);
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final deleteFile = await http.delete(
        url('api/todo/attachment/$idFile'),
        headers: requestHeaders,
      );
      print(deleteFile.body);
      if (deleteFile.statusCode == 200) {
        var deleteFileJson = json.decode(deleteFile.body);
        if (deleteFileJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          getHeaderHTTP();
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        print(deleteFile.body);
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
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      print(e);
    }
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
                            child: Text("Admin",
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
                            child: Text("Executor",
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
                            child: Text("Viewer",
                                style: TextStyle(color: Colors.white)))))
              ],
            ),
          );
        });
  }

  void _updatestatusMember(idMember, roleId) async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addMemberTodo = await http.post(
          url('api/todo_edit/ganti_statusmember'),
          headers: requestHeaders,
          body: {
            'todolist': widget.idTodo.toString(),
            'member': idMember.toString(),
            'role': roleId.toString(),
          });
      print(addMemberTodo.body);
      if (addMemberTodo.statusCode == 200) {
        var addMemberTodoJson = json.decode(addMemberTodo.body);
        if (addMemberTodoJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          getHeaderHTTP();
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        print(addMemberTodo.body);
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
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
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
      appBar: AppBar(
        backgroundColor: primaryAppBarColor,
        title: Text(
            titleEdit == null
                ? 'Tunggu Sebentar...'
                : 'Manajemen ToDo ($titleEdit)',
            style: TextStyle(fontSize: 14)),
        actions: <Widget>[],
      ), //
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
                          child: Text('Information',
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
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
                          child: Text('Member',
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
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
                          child: Text('Document',
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
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
                              : Column(
                                  children: <Widget>[
                                    isError == true
                                        ? Container(
                                            color: Colors.white,
                                            margin: EdgeInsets.only(
                                                top: 0.0,
                                                left: 10.0,
                                                right: 10.0),
                                            padding: const EdgeInsets.only(
                                                top: 10.0, bottom: 15.0),
                                            child: RefreshIndicator(
                                              onRefresh: () => getHeaderHTTP(),
                                              child: Column(children: <Widget>[
                                                new Container(
                                                  width: 100.0,
                                                  height: 100.0,
                                                  child: Image.asset(
                                                      "images/system-eror.png"),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15.0,
                                                          left: 15.0,
                                                          right: 15.0,
                                                          bottom: 15.0),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: RaisedButton(
                                                      color: Colors.white,
                                                      textColor:
                                                          primaryAppBarColor,
                                                      disabledColor:
                                                          Colors.grey,
                                                      disabledTextColor:
                                                          Colors.black,
                                                      padding:
                                                          EdgeInsets.all(15.0),
                                                      onPressed: () async {
                                                        getHeaderHTTP();
                                                      },
                                                      child: Text(
                                                        "Muat Ulang Halaman",
                                                        style: TextStyle(
                                                            fontSize: 14.0,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                          )
                                        : Container(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Container(
                                                    color: Colors.white,
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        Container(
                                                          child: Text(
                                                            'Edit ToDo',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          ),
                                                        ),
                                                        Divider(),
                                                        Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        10.0,
                                                                    top: 10.0),
                                                            child: TextField(
                                                              textAlignVertical:
                                                                  TextAlignVertical
                                                                      .center,
                                                              decoration: InputDecoration(
                                                                  contentPadding:
                                                                      EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                          bottom:
                                                                              2,
                                                                          left:
                                                                              10,
                                                                          right:
                                                                              10),
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  hintText:
                                                                      'Judul ToDo',
                                                                  hintStyle: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black)),
                                                              controller:
                                                                  _titleController,
                                                            )),
                                                        InkWell(
                                                          onTap: () async {
                                                            showCategory();
                                                          },
                                                          child: Container(
                                                            height: 45.0,
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 10.0,
                                                                    right:
                                                                        10.0),
                                                            width:
                                                                double.infinity,
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .black45),
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5.0))),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                Text(
                                                                    categoriesID ==
                                                                            null
                                                                        ? "Pilih Kategori"
                                                                        : 'Kategori - $categoriesName',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .black),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .left),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        categoriesID == '1'
                                                            ? GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              ChooseProjectAvailable()));
                                                                  setState(() {
                                                                    namaProjectEditChoose =
                                                                        namaProjectEditChoose;
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  height: 45.0,
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          top:
                                                                              10.0),
                                                                  padding: EdgeInsets.only(
                                                                      left:
                                                                          10.0,
                                                                      right:
                                                                          10.0),
                                                                  width: double
                                                                      .infinity,
                                                                  decoration: BoxDecoration(
                                                                      border: Border.all(
                                                                          color: Colors
                                                                              .black45),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(5.0))),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: <
                                                                        Widget>[
                                                                      Expanded(
                                                                        child: Text(
                                                                            namaProjectEditChoose == null
                                                                                ? 'Pilih Project'
                                                                                : 'Project $namaProjectEditChoose',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 12,
                                                                            ),
                                                                            overflow: TextOverflow
                                                                                .ellipsis,
                                                                            softWrap:
                                                                                true,
                                                                            maxLines:
                                                                                1,
                                                                            textAlign:
                                                                                TextAlign.left),
                                                                      ),
                                                                      Icon(Icons
                                                                          .chevron_right),
                                                                    ],
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(),
                                                        Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 15.0),
                                                            child: Divider()),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 8.0),
                                                          child: Text(
                                                              "Pelaksanaan Kegiatan"),
                                                        ),
                                                        Row(
                                                          children: <Widget>[
                                                            Container(
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      top: 10.0,
                                                                      bottom:
                                                                          10.0),
                                                              child: SizedBox(
                                                                height: 24.0,
                                                                width: 24.0,
                                                                child: Checkbox(
                                                                  value: _alldayTipe ==
                                                                          '0'
                                                                      ? false
                                                                      : true,

                                                                  // checkColor: Colors.green,
                                                                  activeColor:
                                                                      primaryAppBarColor,
                                                                  onChanged: (bool
                                                                      value) {
                                                                    setState(
                                                                        () {
                                                                      _alldayTipe = value ==
                                                                              true
                                                                          ? '1'
                                                                          : '0';
                                                                      _dateStartController
                                                                          .text = '';
                                                                      _dateEndController
                                                                          .text = '';
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                            Text("All Day")
                                                          ],
                                                        ),
                                                        Container(
                                                            alignment: Alignment
                                                                .center,
                                                            height: 45.0,
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        10.0),
                                                            child:
                                                                DateTimeField(
                                                              controller:
                                                                  _dateStartController,
                                                              format: _alldayTipe ==
                                                                      '0'
                                                                  ? DateFormat(
                                                                      "dd-MM-yyyy HH:mm:ss")
                                                                  : DateFormat(
                                                                      "dd-MM-yyyy "),
                                                              readOnly: true,
                                                              decoration:
                                                                  InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets.only(
                                                                        top: 2,
                                                                        bottom:
                                                                            2,
                                                                        left:
                                                                            10,
                                                                        right:
                                                                            10),
                                                                border:
                                                                    OutlineInputBorder(),
                                                                hintText:
                                                                    'Tanggal Mulainya ToDo',
                                                                hintStyle: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              onShowPicker:
                                                                  (context,
                                                                      currentValue) async {
                                                                final date = await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    firstDate:
                                                                        DateTime(
                                                                            2018),
                                                                    initialDate: _dateStartController
                                                                                .text !=
                                                                            ''
                                                                        ? DateFormat("dd-MM-yyyy").parse(
                                                                            "${_dateStartController.text}")
                                                                        : _dateEndController.text ==
                                                                                ''
                                                                            ? DateTime
                                                                                .now()
                                                                            : DateFormat("dd-MM-yyyy").parse(
                                                                                "${_dateEndController.text}"),
                                                                    lastDate: _dateEndController
                                                                                .text ==
                                                                            ''
                                                                        ? DateTime(
                                                                            2100)
                                                                        : DateFormat("dd-MM-yyyy")
                                                                            .parse("${_dateEndController.text}"));
                                                                if (date !=
                                                                    null) {
                                                                  if (_alldayTipe ==
                                                                      '0') {
                                                                    final times =
                                                                        await showTimePicker(
                                                                      context:
                                                                          context,
                                                                      initialTime:
                                                                          TimeOfDay.fromDateTime(
                                                                              DateTime.now()),
                                                                    );
                                                                    return DateTimeField
                                                                        .combine(
                                                                            date,
                                                                            times);
                                                                  } else {
                                                                    final time =
                                                                        TimeOfDay.fromDateTime(
                                                                            DateTime.now());
                                                                    return DateTimeField
                                                                        .combine(
                                                                            date,
                                                                            time);
                                                                  }
                                                                } else {
                                                                  return currentValue;
                                                                }
                                                              },
                                                              onChanged: (ini) {
                                                                setState(() {
                                                                  // _dateEndController.text = '';
                                                                });
                                                              },
                                                            )),
                                                        Container(
                                                            alignment: Alignment
                                                                .center,
                                                            height: 45.0,
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        10.0),
                                                            child:
                                                                DateTimeField(
                                                              onChanged: (ini) {
                                                                if (_dateStartController
                                                                        .text ==
                                                                    '') {
                                                                  if (_alldayTipe ==
                                                                      '0') {
                                                                    setState(
                                                                        () {
                                                                      _dateStartController
                                                                              .text =
                                                                          _dateEndController
                                                                              .text;
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      _dateStartController
                                                                              .text =
                                                                          _dateEndController
                                                                              .text;
                                                                    });
                                                                  }
                                                                }
                                                              },
                                                              controller:
                                                                  _dateEndController,
                                                              format: _alldayTipe ==
                                                                      '0'
                                                                  ? DateFormat(
                                                                      "dd-MM-yyyy HH:mm:ss")
                                                                  : DateFormat(
                                                                      "dd-MM-yyyy "),
                                                              readOnly: true,
                                                              decoration:
                                                                  InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets.only(
                                                                        top: 2,
                                                                        bottom:
                                                                            2,
                                                                        left:
                                                                            10,
                                                                        right:
                                                                            10),
                                                                border:
                                                                    OutlineInputBorder(),
                                                                hintText:
                                                                    'Tanggal Berakhirnya ToDo',
                                                                hintStyle: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              onShowPicker:
                                                                  (context,
                                                                      currentValue) async {
                                                                DateFormat
                                                                    inputFormat =
                                                                    DateFormat(
                                                                        "dd-MM-yyyy");

                                                                final date = await showDatePicker(
                                                                    context:
                                                                        context,
                                                                    firstDate: _dateStartController.text ==
                                                                            ''
                                                                        ? DateTime(
                                                                            2000)
                                                                        : inputFormat.parse(
                                                                            "${_dateStartController.text}"),
                                                                    initialDate: _dateEndController.text ==
                                                                            ''
                                                                        ? _dateStartController.text ==
                                                                                ''
                                                                            ? DateTime
                                                                                .now()
                                                                            : inputFormat.parse(
                                                                                "${_dateStartController.text}")
                                                                        : inputFormat.parse(
                                                                            "${_dateEndController.text}"),
                                                                    lastDate:
                                                                        DateTime(
                                                                            2100));
                                                                if (date !=
                                                                    null) {
                                                                  if (_alldayTipe ==
                                                                      '0') {
                                                                    final times =
                                                                        await showTimePicker(
                                                                      context:
                                                                          context,
                                                                      initialTime:
                                                                          TimeOfDay.fromDateTime(
                                                                              DateTime.now()),
                                                                    );
                                                                    return DateTimeField
                                                                        .combine(
                                                                            date,
                                                                            times);
                                                                  } else {
                                                                    final time =
                                                                        TimeOfDay.fromDateTime(
                                                                            DateTime.now());
                                                                    return DateTimeField
                                                                        .combine(
                                                                            date,
                                                                            time);
                                                                  }
                                                                } else {
                                                                  return currentValue;
                                                                }
                                                              },
                                                            )),
                                                        Divider(),
                                                        Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        10.0,
                                                                    top: 10.0),
                                                            height: 120.0,
                                                            child: TextField(
                                                              maxLines: 10,
                                                              controller:
                                                                  _descController,
                                                              textAlignVertical:
                                                                  TextAlignVertical
                                                                      .center,
                                                              decoration: InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  hintText:
                                                                      'Deskripsi',
                                                                  hintStyle: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black)),
                                                            )),
                                                        Container(
                                                            width:
                                                                double.infinity,
                                                            margin:
                                                                EdgeInsets.only(
                                                                    bottom: 16),
                                                            child: RaisedButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          15.0),
                                                              color:
                                                                  primaryAppBarColor,
                                                              child: Text(
                                                                  "Simpan",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                              onPressed:
                                                                  () async {
                                                                if (_titleController
                                                                        .text ==
                                                                    '') {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Nama ToDo Tidak Boleh Kosong");
                                                                } else if (categoriesID
                                                                            .toString() ==
                                                                        '' ||
                                                                    categoriesID ==
                                                                        null) {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Kategori Tidak Boleh Kosong");
                                                                } else if (_dateStartController
                                                                        .text ==
                                                                    '') {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Tanggal Dimulainya ToDo Tidak Boleh Kosong");
                                                                } else if (_dateEndController
                                                                        .text ==
                                                                    '') {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Tanggal Berakhirnya ToDo Tidak Boleh Kosong");
                                                                } else if (_descController
                                                                        .text ==
                                                                    '') {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Deskripsi tidak boleh kosong");
                                                                } else if (categoriesID
                                                                        .toString() ==
                                                                    '1') {
                                                                  if (idProjectEditChoose ==
                                                                      null) {
                                                                    Fluttertoast
                                                                        .showToast(
                                                                            msg:
                                                                                "Silahkan Pilih Project Terlebih Dahulu");
                                                                  } else {
                                                                    saveTodo();
                                                                  }
                                                                } else {
                                                                  saveTodo();
                                                                }
                                                              },
                                                            )),
                                                      ],
                                                    )),
                                              ],
                                            ),
                                          ),
                                    isLoading == true
                                        ? Container()
                                        : dataStatusKita == null
                                            ? Container()
                                            : dataStatusKita['tlr_role'] ==
                                                        '1' ||
                                                    dataStatusKita[
                                                            'tlr_role'] ==
                                                        1
                                                ? Container(
                                                    color: Colors.red[100],
                                                    margin: EdgeInsets.only(
                                                        top: 15.0,
                                                        left: 5.0,
                                                        right: 5.0,
                                                        bottom: 15.0),
                                                    padding: EdgeInsets.only(
                                                        left: 10.0,
                                                        right: 10.0,
                                                        top: 5.0,
                                                        bottom: 5.0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Text(
                                                              'Ingin Menghapus ToDo Ini ?',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black87)),
                                                        ),
                                                        ButtonTheme(
                                                            minWidth: 0,
                                                            height: 0,
                                                            child: FlatButton(
                                                                // borderSide: BorderSide(color:Colors.red),
                                                                color: Colors
                                                                    .red[400],
                                                                onPressed:
                                                                    () async {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => ManageDeleteTodo(
                                                                                idtodo: dataTodo['tl_id'],
                                                                                namatodo: dataTodo['tl_title'],
                                                                              )));
                                                                },
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            15.0,
                                                                        right:
                                                                            15.0,
                                                                        top:
                                                                            10.0,
                                                                        bottom:
                                                                            10.0),
                                                                child: Text(
                                                                  'Hapus',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ))),
                                                      ],
                                                    ),
                                                  )
                                                : Container(),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  isLoading == true
                      ? _loadingview()
                      : Container(
                          child: SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(10.0),
                                  margin: EdgeInsets.only(bottom: 15.0),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10.0),
                                        child: Text(
                                          'Tambah Member',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
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
                                                TextAlignVertical.center,
                                            controller: _controllerNamaMember,
                                            onChanged: (text) {
                                              setState(() {
                                                emailMemberFriend = null;
                                                nameMemberFriend = null;
                                              });
                                            },
                                            decoration: InputDecoration(
                                                contentPadding: EdgeInsets.only(
                                                    top: 2,
                                                    bottom: 2,
                                                    left: 10,
                                                    right: 10),
                                                border: OutlineInputBorder(),
                                                hintText:
                                                    'Masukkan Email Pengguna',
                                                hintStyle: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                )),
                                          )),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 5.0, bottom: 5.0),
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 5.0),
                                              child: Text(
                                                'Atau Dari Daftar Teman ?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 6,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    border: BorderDirectional(
                                                        bottom: BorderSide(
                                                  width: 1 / 2,
                                                  color: Colors.black54,
                                                ))),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          _controllerNamaMember.clear();
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      WidgetFriendList()));
                                          setState(() {
                                            emailMemberFriend =
                                                emailMemberFriend;
                                            nameMemberFriend = nameMemberFriend;
                                          });
                                        },
                                        child: Container(
                                          height: 40.0,
                                          padding: EdgeInsets.only(
                                              left: 5.0, right: 5.0),
                                          margin: EdgeInsets.only(
                                              top: 5.0, bottom: 10.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black45,
                                                width: 1.0),
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(
                                                emailMemberFriend != null
                                                    ? '$emailMemberFriend'
                                                    : 'Pilih Dari Daftar Teman',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              emailMemberFriend != null
                                                  ? GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          emailMemberFriend =
                                                              null;
                                                          nameMemberFriend =
                                                              null;
                                                        });
                                                      },
                                                      child: Container(
                                                          child: Icon(
                                                        Icons.close,
                                                        color: Colors.red,
                                                      )),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Divider(),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          'Level Member',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: 'Roboto',
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(top: 0.0),
                                        padding: EdgeInsets.only(
                                            left: 10.0, right: 10.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black45),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0))),
                                        child: DropdownButtonHideUnderline(
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
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              width: double.infinity,
                                              height: 40.0,
                                              child: RaisedButton(
                                                  onPressed: () async {
                                                    print(emailMemberFriend);
                                                    String emailValid =
                                                        emailMemberFriend !=
                                                                null
                                                            ? emailMemberFriend
                                                            : _controllerNamaMember
                                                                .text;
                                                    final bool isValid =
                                                        EmailValidator.validate(
                                                            emailValid);
                                                    print('Email is valid? ' +
                                                        (isValid
                                                            ? 'yes'
                                                            : 'no'));
                                                    if (emailValid == null ||
                                                        emailValid == '') {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "Email Tidak Boleh Kosong");
                                                    } else if (!isValid) {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "Masukkan Email Yang Valid");
                                                    } else if (_urutkanvalue ==
                                                        null) {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              "Pilih Level Member");
                                                    } else {
                                                      tambahkanMember();
                                                    }
                                                  },
                                                  color: primaryAppBarColor,
                                                  textColor: Colors.white,
                                                  disabledColor: Color.fromRGBO(
                                                      254, 86, 14, 0.7),
                                                  disabledTextColor:
                                                      Colors.white,
                                                  splashColor:
                                                      Colors.blueAccent,
                                                  child: Text(
                                                      "Tambahkan Member",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.white)))))
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 0.0),
                                  padding: EdgeInsets.all(5.0),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                          child: Column(
                                              children: listMemberTodo
                                                  .map(
                                                      (MemberTodo item) => Card(
                                                            elevation: 0.5,
                                                            child: ListTile(
                                                              leading:
                                                                  Container(
                                                                height: 40.0,
                                                                width: 40.0,
                                                                child: ClipOval(
                                                                    child: FadeInImage
                                                                        .assetNetwork(
                                                                  placeholder:
                                                                      'images/loading.gif',
                                                                  image: item.image ==
                                                                              null ||
                                                                          item.image ==
                                                                              ''
                                                                      ? url(
                                                                          'assets/images/imgavatar.png')
                                                                      : url(
                                                                          'storage/image/profile/${item.image}'),
                                                                )),
                                                              ),
                                                              title: Text(
                                                                item.name ==
                                                                            null ||
                                                                        item.name ==
                                                                            ''
                                                                    ? 'Member Tidak Diketahui'
                                                                    : item.name,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                              ),
                                                              subtitle: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top:
                                                                            10.0),
                                                                child: Text(
                                                                  item.rolename ==
                                                                              null ||
                                                                          item.rolename ==
                                                                              ''
                                                                      ? 'Status Tidak Diketahui'
                                                                      : item
                                                                          .rolename,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .green,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                ),
                                                              ),
                                                              trailing: item.roleid ==
                                                                      '1'
                                                                  ? ButtonTheme(
                                                                      minWidth:
                                                                          0,
                                                                      height: 0,
                                                                      child: FlatButton(
                                                                          padding: EdgeInsets.all(
                                                                              0),
                                                                          color: Colors
                                                                              .white,
                                                                          onPressed:
                                                                              () async {},
                                                                          child: Icon(
                                                                              item.roleid == '1' ? Icons.lock : Icons.delete,
                                                                              color: item.roleid == '1' ? Colors.grey : Colors.red)))
                                                                  : PopupMenuButton<String>(
                                                                      onSelected:
                                                                          (String
                                                                              value) {
                                                                        switch (
                                                                            value) {
                                                                          case 'Hapus Member':
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) => AlertDialog(
                                                                                title: Text('Peringatan!'),
                                                                                content: Text('Apakah Anda Ingin Menghapus Member ToDo'),
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
                                                                                      deleteMember(item.iduser);
                                                                                    },
                                                                                  )
                                                                                ],
                                                                              ),
                                                                            );

                                                                            break;
                                                                          case 'Ganti Status':
                                                                            gantiStatusMember(item.iduser,
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
                                                                              'Ganti Status',
                                                                          child:
                                                                              Text("Ganti Status Member"),
                                                                        ),
                                                                        PopupMenuItem(
                                                                          value:
                                                                              'Hapus Member',
                                                                          child:
                                                                              Text("Hapus Member"),
                                                                        ),
                                                                      ],
                                                                    ),
                                                            ),
                                                          ))
                                                  .toList()))
                                    ],
                                  ),
                                )
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
                              : Column(
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(10.0),
                                      margin: EdgeInsets.only(bottom: 15.0),
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            margin:
                                                EdgeInsets.only(bottom: 10.0),
                                            child: Text(
                                              'Tambah Document',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Divider(),
                                          _loadingPath == true
                                              ? Container()
                                              : Container(),
                                          InkWell(
                                            onTap: () async {
                                              _openFileExplorer();
                                            },
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  left: 10.0,
                                                  right: 10.0,
                                                  top: 15.0,
                                                  bottom: 15.0),
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black45),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              5.0))),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(
                                                      filename == null ||
                                                              filename == ''
                                                          ? 'Pilih File'
                                                          : '$filename',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                      textAlign:
                                                          TextAlign.left),
                                                ],
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
                                                        if (fileImage == null ||
                                                            fileImage == '') {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  "Pilih File Terlebih Dahulu");
                                                        } else {
                                                          tambahkanFile();
                                                        }
                                                      },
                                                      color: primaryAppBarColor,
                                                      textColor: Colors.white,
                                                      disabledColor:
                                                          Color.fromRGBO(
                                                              254, 86, 14, 0.7),
                                                      disabledTextColor:
                                                          Colors.white,
                                                      splashColor:
                                                          Colors.blueAccent,
                                                      child: Text(
                                                          "Tambahkan Document",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)))))
                                        ],
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 0.0),
                                      padding: EdgeInsets.all(15.0),
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          listFileTodo.length == 0
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 20.0),
                                                  child:
                                                      Column(children: <Widget>[
                                                    new Container(
                                                      width: 100.0,
                                                      height: 100.0,
                                                      child: Image.asset(
                                                          "images/icon_document.png"),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        top: 20.0,
                                                        left: 15.0,
                                                        right: 15.0,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Document ToDo Belum Ditambahkan",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black45,
                                                            height: 1.5,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ]),
                                                )
                                              : Container(
                                                  child: Column(
                                                      children: listFileTodo
                                                          .map(
                                                              (FileTodo item) =>
                                                                  Card(
                                                                    elevation:
                                                                        0.5,
                                                                    child:
                                                                        ListTile(
                                                                      leading:
                                                                          Icon(
                                                                        Icons
                                                                            .insert_drive_file,
                                                                        color: Colors
                                                                            .red,
                                                                      ),
                                                                      title:
                                                                          Text(
                                                                        item.path == null ||
                                                                                item.path == ''
                                                                            ? 'File Tidak Diketahui'
                                                                            : item.path,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        softWrap:
                                                                            true,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                      trailing: ButtonTheme(
                                                                          minWidth: 0,
                                                                          height: 0,
                                                                          child: FlatButton(
                                                                            padding:
                                                                                EdgeInsets.all(0),
                                                                            onPressed:
                                                                                () async {
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) => AlertDialog(
                                                                                  title: Text('Peringatan!'),
                                                                                  content: Text('Apakah Anda Ingin Menghapus Document ToDo'),
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
                                                                                        deleteFile(item.id);
                                                                                      },
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                            color:
                                                                                Colors.white,
                                                                            child:
                                                                                Icon(Icons.delete, color: Colors.red),
                                                                          )),
                                                                    ),
                                                                  ))
                                                          .toList()))
                                        ],
                                      ),
                                    )
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
          top: 0.0,
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

  // Widget _bottomButtons() {
  //   return _tabController.index == 0
  //       ? DraggableFab(
  //           child: FloatingActionButton(
  //               shape: StadiumBorder(),
  //               onPressed: () async {
  //                 if (_titleController.text == '') {
  //                   Fluttertoast.showToast(
  //                       msg: "Nama To Do Tidak Boleh Kosong");
  //                 } else if (categoriesID.toString() == '' ||
  //                     categoriesID == null) {
  //                   Fluttertoast.showToast(msg: "Kategori Tidak Boleh Kosong");
  //                 } else if (_dateStartController.text == '') {
  //                   Fluttertoast.showToast(
  //                       msg: "Tanggal Dimulainya To Do Tidak Boleh Kosong");
  //                 } else if (_dateEndController.text == '') {
  //                   Fluttertoast.showToast(
  //                       msg: "Tanggal Berakhirnya To Do Tidak Boleh Kosong");
  //                 } else if (categoriesID.toString() == '1') {
  //                   if (idProjectEditChoose == null) {
  //                     Fluttertoast.showToast(
  //                         msg: "Silahkan Pilih Project Terlebih Dahulu");
  //                   } else {
  //                     saveTodo();
  //                   }
  //                 } else {
  //                   saveTodo();
  //                 }
  //               },
  //               backgroundColor: Color.fromRGBO(254, 86, 14, 1),
  //               child: Icon(
  //                 Icons.check,
  //                 size: 20.0,
  //               )))
  //       : _tabController.index == 1 ? null : null;
  // }

  void saveTodo() async {
    await progressApiAction.show();
    try {
      dynamic body = {
        "title": _titleController.text.toString(),
        "planstart": _dateStartController.text.toString(),
        "planend": _dateEndController.text.toString(),
        "desc": _descController.text.toString(),
        'allday': _alldayTipe.toString(),
        "category": categoriesID.toString(),
        'project': idProjectEditChoose.toString(),
      };
      print(body);
      final tambahfile = await http.patch(
          url('api/todo/update/${widget.idTodo}'),
          headers: requestHeaders,
          body: body);
      print(tambahfile.statusCode);
      if (tambahfile.statusCode == 200) {
        var tambahFileJson = json.decode(tambahfile.body);
        if (tambahFileJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: 'success');
          getHeaderHTTP();
        }
      } else {
        print(tambahfile.body);
        progressApiAction.hide().then((isHidden) {});
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {});
      Fluttertoast.showToast(msg: "Timed out, Try again");
    }
  }

  void showCategory() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return SingleChildScrollView(
              child: Container(
            // height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 5.0,
                left: 5.0,
                top: 40.0),
            child: Column(children: <Widget>[
              for (int i = 0; i < listCategory.length; i++)
                InkWell(
                    onTap: () async {
                      setState(() {
                        categoriesID = listCategory[i].id.toString();
                        categoriesName = listCategory[i].name.toString();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(listCategory[i].name),
                        ),
                      ),
                    )),
            ]),
          ));
        });
  }
}
