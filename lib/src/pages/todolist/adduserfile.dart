import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/models/attachment.dart';
import 'package:todolist_app/src/models/user.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:email_validator/email_validator.dart';

String radioItem = 'Admin';
int idChooseRole;
enum PageEnum { editPeserta, hapusPeserta }

class AddUserFileTodo extends StatefulWidget {
  final idTodo;
  AddUserFileTodo({Key key, this.idTodo});
  @override
  _AddUserFileTodoState createState() => _AddUserFileTodoState();
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _AddUserFileTodoState extends State<AddUserFileTodo>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  bool isLoading, isError, isAccess, isFilter, isErrorfilter, isCreate;
  String tokenType, accessToken;
  List<User> listUserItem = [];
  TextEditingController _controllerNamaMember = TextEditingController();
  String _urutkanvalue;
  List<User> listFilterItem = [];
  List<Attachment> listAttachmentItem = [];
  ProgressDialog progressApiAction;
  String userID;
  FileType _pickingType;
  bool _hasValidMime = false;
  Map<String, String> requestHeaders = Map();
  TextEditingController _searchQuery = new TextEditingController();
  String pathname;
  String fileImage;
  String filename;

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var userId = await storage.getDataString('id');
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    userID = userId;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    return listUser(1);
  }

  Future<List<List>> listUser(access) async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      isLoading = true;
    });
    listUserItem.clear();
    try {
      final getUser = await http.get(
        url('api/todo/peserta/${widget.idTodo}/$access'),
        headers: requestHeaders,
      );
      print(widget.idTodo);

      if (getUser.statusCode == 200) {
        var listuserJson = json.decode(getUser.body);
        var listUsers = listuserJson['users'];
        var roleUser = listuserJson['roleUser'];
        listUserItem = [];
        for (var i in listUsers) {
          User willcomex = User(
              id: i['id'],
              name: i['name'],
              email: i['email'],
              todo: i['todo'],
              owner: i['owner'],
              idaccess: i['idaccess'],
              image: i['image'],
              access: i['access']);
          listUserItem.add(willcomex);

          if (roleUser == 1 || roleUser == 2) {
            setState(() {
              isAccess = true;
            });
          } else {
            setState(() {
              isAccess = false;
            });
          }
        }
        return listAttachment();
      } else if (getUser.statusCode == 401) {
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

  Future<List<List>> listAttachment() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      isLoading = true;
    });
    listAttachmentItem.clear();
    try {
      final getUser = await http.get(
        url('api/todo/attachment/${widget.idTodo}'),
        headers: requestHeaders,
      );
      print(widget.idTodo);

      if (getUser.statusCode == 200) {
        var listUsers = json.decode(getUser.body);
        for (var i in listUsers) {
          Attachment willcomex =
              Attachment(id: i['id'], path: i['path'], todo: i['todo']);
          listAttachmentItem.add(willcomex);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getUser.statusCode == 401) {
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

  void _updatestatusMember(idMember) async {
    print(idChooseRole.toString());
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addMemberTodo = await http.post(
          url('api/todo_edit/ganti_statusmember'),
          headers: requestHeaders,
          body: {
            'todolist': widget.idTodo.toString(),
            'member': idMember.toString(),
            'role': idChooseRole.toString(),
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

  void deleteFile(int index, int id) async {
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addpeserta = await http.delete(
        url('api/todo/attachment/$id'),
        headers: requestHeaders,
      );

      if (addpeserta.statusCode == 200) {
        var addpesertaJson = json.decode(addpeserta.body);
        if (addpesertaJson['status'] == 'success') {
          listAttachmentItem.removeAt(index);
          setState(() {
            pathname = '';
            isCreate = false;
          });
          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (addpesertaJson['status'] == 'owner') {
          Fluttertoast.showToast(msg: "Pengguna Ini Merupakan Pembuat ToDo");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else if (addpesertaJson['status'] == 'exists') {
          Fluttertoast.showToast(msg: "Pengguna Sudah Terdaftar");
          progressApiAction.hide().then((isHidden) {});
          setState(() {
            isCreate = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Status Tidak Diketahui");
          progressApiAction.hide().then((isHidden) {});
          Navigator.pop(context);
          setState(() {
            isCreate = false;
          });
        }
      } else {
        print(addpeserta.body);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {});
        setState(() {
          isCreate = false;
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}");
      progressApiAction.hide().then((isHidden) {});
      setState(() {
        isCreate = false;
      });
      print(e);
    }
  }

  void tambahkanMember() async {
    await progressApiAction.show();
    try {
      final addMemberTodo = await http.post(url('api/todo_edit/tambah_member'),
          headers: requestHeaders,
          body: {
            'todolist': widget.idTodo.toString(),
            'member': _controllerNamaMember.text,
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
          });
        } else if (addMemberTodoJson['status'] == 'email belum terdaftar') {
          Fluttertoast.showToast(msg: "Email Ini Belum Memiliki Akun Pengguna");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          setState(() {
            _controllerNamaMember.text = '';
            _urutkanvalue = null;
          });
        } else if (addMemberTodoJson['status'] == 'member sudah terdaftar') {
          Fluttertoast.showToast(msg: "Member Ini Sudah Terdaftar Pada To Do");
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          setState(() {
            _controllerNamaMember.text = '';
            _urutkanvalue = null;
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
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      setState(() {
        _controllerNamaMember.text = '';
        _urutkanvalue = null;
      });
      print(e);
    }
  }

  void tambahkanFile() async {
    await progressApiAction.show();
    try {
      dynamic body = {
        'file64': fileImage.toString(),
        'pathname': pathname,
        'filename': filename,
        'todolist': widget.idTodo.toString(),
      };
      print(body);
      final tambahfile = await http.post(url('api/todo_edit/tambah_file'),
          headers: requestHeaders, body: body);
      if (tambahfile.statusCode == 200) {
        var tambahFileJson = json.decode(tambahfile.body);
        if (tambahFileJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: 'success');
          setState(() {
            fileImage = null;
            pathname = null;
            filename = null;
          });
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

  void deletePeserta(index) async {
    await progressApiAction.show();
    try {
      final removeConfirmation = await http.delete(
          url('api/todo/peserta/delete/${listUserItem[index].id.toString()}/${listUserItem[index].todo.toString()}'),
          headers: requestHeaders);
      print(removeConfirmation);
      if (removeConfirmation.statusCode == 200) {
        var removeConfirmationJson = json.decode(removeConfirmation.body);
        if (removeConfirmationJson['status'] == 'success') {
          setState(() {
            listUserItem.remove(listUserItem[index]);
          });

          Fluttertoast.showToast(msg: "Berhasil");
          progressApiAction.hide().then((isHidden) {});
        } else if (removeConfirmationJson['status'] == 'Error') {
          Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
          progressApiAction.hide().then((isHidden) {});
        }
      } else {
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Lagi");
        progressApiAction.hide().then((isHidden) {});
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Timed out, Try again");
      progressApiAction.hide().then((isHidden) {});
    } catch (e) {
      Fluttertoast.showToast(msg: "${e.toString()}'");
      progressApiAction.hide().then((isHidden) {});
      print(e);
    }
  }

  @override
  void initState() {
    getHeaderHTTP();
    _searchQuery.text = '';
    idChooseRole = 2;
    _tabController = TabController(
        length: 2, vsync: _AddUserFileTodoState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    super.initState();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    super.dispose();
  }

  Future<bool> _willPopCallback() async {
    return false;
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
    return WillPopScope(
        onWillPop: () => _willPopCallback(),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryAppBarColor,
            title: Text('Tambah Peserta Dan Document',
                style: TextStyle(
                  fontSize: 14,
                )),
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => Dashboard()),
                      ModalRoute.withName('/'));
                },
                icon: Icon(Icons.check),
              )
            ],
          ),
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
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Text('Peserta',
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
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Text('Document',
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
                      RefreshIndicator(
                        onRefresh: () async {
                          getHeaderHTTP();
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              isLoading == true
                                  ? _loadingview()
                                  : Column(
                                      children: <Widget>[
                                        isError == true
                                            ? errorView()
                                            : Container(
                                                padding: EdgeInsets.all(10.0),
                                                margin: EdgeInsets.only(
                                                    bottom: 15.0),
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
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                    ),
                                                    Divider(),
                                                    Container(
                                                        alignment:
                                                            Alignment.center,
                                                        height: 40.0,
                                                        margin: EdgeInsets.only(
                                                            bottom: 5.0,
                                                            top: 5.0),
                                                        child: TextField(
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          controller:
                                                              _controllerNamaMember,
                                                          decoration:
                                                              InputDecoration(
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
                                                                      'Masukkan Email Pengguna',
                                                                  hintStyle:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black,
                                                                  )),
                                                        )),
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          top: 0.0),
                                                      padding: EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 10.0),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: Colors
                                                                  .black45),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5.0))),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                            String>(
                                                          isExpanded: true,
                                                          items: [
                                                            DropdownMenuItem<
                                                                String>(
                                                              child: Text(
                                                                'Admin',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                              value: '2',
                                                            ),
                                                            DropdownMenuItem<
                                                                String>(
                                                              child: Text(
                                                                'Executor',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                              value: '3',
                                                            ),
                                                            DropdownMenuItem<
                                                                String>(
                                                              child: Text(
                                                                'Viewer',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                              value: '4',
                                                            ),
                                                          ],
                                                          value: _urutkanvalue ==
                                                                  null
                                                              ? null
                                                              : _urutkanvalue,
                                                          onChanged:
                                                              (String value) {
                                                            setState(() {
                                                              _urutkanvalue =
                                                                  value;
                                                            });
                                                          },
                                                          hint: Text(
                                                            'Pilih level Member',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                        child: Container(
                                                            margin: EdgeInsets
                                                                .only(
                                                                    top: 10.0),
                                                            width:
                                                                double.infinity,
                                                            height: 40.0,
                                                            child: RaisedButton(
                                                                onPressed:
                                                                    () async {
                                                                  String
                                                                      emailValid =
                                                                      _controllerNamaMember
                                                                          .text;
                                                                  final bool
                                                                      isValid =
                                                                      EmailValidator
                                                                          .validate(
                                                                              emailValid);
                                                                  print('Email is valid? ' +
                                                                      (isValid
                                                                          ? 'yes'
                                                                          : 'no'));
                                                                  if (_controllerNamaMember
                                                                              .text ==
                                                                          null ||
                                                                      _controllerNamaMember
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
                                                                    tambahkanMember();
                                                                  }
                                                                },
                                                                color:
                                                                    primaryAppBarColor,
                                                                textColor:
                                                                    Colors
                                                                        .white,
                                                                disabledColor:
                                                                    Color.fromRGBO(
                                                                        254,
                                                                        86,
                                                                        14,
                                                                        0.7),
                                                                disabledTextColor:
                                                                    Colors
                                                                        .white,
                                                                splashColor: Colors
                                                                    .blueAccent,
                                                                child: Text(
                                                                    "Tambahkan Member",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .white)))))
                                                  ],
                                                ),
                                              ),
                                        Container(
                                          color: Colors.white,
                                          margin: EdgeInsets.only(
                                            top: 0.0,
                                          ),
                                          padding: EdgeInsets.all(10.0),
                                          child: Container(
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  for (int item = 0;
                                                      item <
                                                          listUserItem.length;
                                                      item++)
                                                    Card(
                                                        elevation: 0.6,
                                                        child: ListTile(
                                                            title: Text(
                                                                listUserItem[item].name == '' || listUserItem[item].name == null
                                                                    ? 'Nama Peserta Tidak Diketahui'
                                                                    : listUserItem[item]
                                                                        .name,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: true,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500)),
                                                            leading: Container(
                                                              height: 40.0,
                                                              width: 40.0,
                                                              child: ClipOval(
                                                                  child: FadeInImage
                                                                      .assetNetwork(
                                                                placeholder:
                                                                    'images/loading.gif',
                                                                image: listUserItem[item].image ==
                                                                            null ||
                                                                        listUserItem[item].image ==
                                                                            ''
                                                                    ? url(
                                                                        'assets/images/imgavatar.png')
                                                                    : url(
                                                                        'storage/image/profile/${listUserItem[item].image}'),
                                                              )),
                                                            ),
                                                            subtitle: Padding(
                                                                padding: EdgeInsets.only(
                                                                    top: 10.0),
                                                                child: Text(
                                                                  listUserItem[item].access ==
                                                                              null ||
                                                                          listUserItem[item].access ==
                                                                              ''
                                                                      ? 'Status Tidak Diketahui'
                                                                      : listUserItem[
                                                                              item]
                                                                          .access,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .green,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                )),
                                                            trailing:
                                                                listUserItem[item]
                                                                            .idaccess ==
                                                                        1
                                                                    ? ButtonTheme(
                                                                        minWidth:
                                                                            0,
                                                                        height:
                                                                            0,
                                                                        child: FlatButton(
                                                                            padding:
                                                                                EdgeInsets.all(0),
                                                                            color: Colors.white,
                                                                            onPressed: () async {},
                                                                            child: Icon(Icons.lock, color: Colors.grey)))
                                                                    : PopupMenuButton<PageEnum>(
                                                                        onSelected:
                                                                            (PageEnum
                                                                                value) {
                                                                          switch (
                                                                              value) {
                                                                            case PageEnum.editPeserta:
                                                                              dialogAddPermision(listUserItem[item].id);
                                                                              break;

                                                                            case PageEnum.hapusPeserta:
                                                                              showDialog(
                                                                                context: context,
                                                                                builder: (BuildContext context) => AlertDialog(
                                                                                  title: Text('Peringatan!'),
                                                                                  content: Text("Apakah Anda Yakin?"),
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
                                                                                        deletePeserta(item);
                                                                                      },
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              );

                                                                              break;
                                                                            default:
                                                                          }
                                                                        },
                                                                        itemBuilder:
                                                                            (context) =>
                                                                                [
                                                                          PopupMenuItem(
                                                                            value:
                                                                                PageEnum.editPeserta,
                                                                            child:
                                                                                Text("Ganti Status"),
                                                                          ),
                                                                          PopupMenuItem(
                                                                            value:
                                                                                PageEnum.hapusPeserta,
                                                                            child:
                                                                                Text("Hapus"),
                                                                          ),
                                                                        ],
                                                                      )))
                                                ]),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: () async {
                          getHeaderHTTP();
                        },
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              isLoading == true
                                  ? _loadingview()
                                  : isError == true
                                      ? errorView()
                                      : Column(
                                          children: <Widget>[
                                            Container(
                                              padding: EdgeInsets.all(10.0),
                                              margin:
                                                  EdgeInsets.only(bottom: 15.0),
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
                                                      'Tambah Document',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                  Divider(),
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
                                                              color: Colors
                                                                  .black45),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5.0))),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Text(
                                                              filename == null ||
                                                                      filename ==
                                                                          ''
                                                                  ? 'Pilih File'
                                                                  : '$filename',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black),
                                                              textAlign:
                                                                  TextAlign
                                                                      .left),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                      child: Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  top: 10.0),
                                                          width:
                                                              double.infinity,
                                                          height: 40.0,
                                                          child: RaisedButton(
                                                              onPressed:
                                                                  () async {
                                                                if (fileImage ==
                                                                        null ||
                                                                    fileImage ==
                                                                        '') {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              "Pilih File Terlebih Dahulu");
                                                                } else {
                                                                  tambahkanFile();
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
                                                              splashColor: Colors
                                                                  .blueAccent,
                                                              child: Text(
                                                                  "Tambahkan Document",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .white)))))
                                                ],
                                              ),
                                            ),
                                            Container(
                                                padding: EdgeInsets.all(15.0),
                                                color: Colors.white,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    listAttachmentItem.length ==
                                                            0
                                                        ? Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 20.0),
                                                            child: Column(
                                                                children: <
                                                                    Widget>[
                                                                  new Container(
                                                                    width:
                                                                        100.0,
                                                                    height:
                                                                        100.0,
                                                                    child: Image
                                                                        .asset(
                                                                            "images/icon_document.png"),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .only(
                                                                      top: 20.0,
                                                                      left:
                                                                          15.0,
                                                                      right:
                                                                          15.0,
                                                                    ),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        "Document To Do Belum Ditambahkan",
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color:
                                                                              Colors.black54,
                                                                          height:
                                                                              1.5,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ]),
                                                          )
                                                        : Column(
                                                            children: <Widget>[
                                                              for (int item = 0;
                                                                  item <
                                                                      listAttachmentItem
                                                                          .length;
                                                                  item++)
                                                                Container(
                                                                    margin: EdgeInsets.only(
                                                                        bottom:
                                                                            10.0),
                                                                    child: Card(
                                                                      elevation:
                                                                          0.5,
                                                                      child:
                                                                          ListTile(
                                                                        leading:
                                                                            Icon(
                                                                          Icons
                                                                              .insert_drive_file,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                        title:
                                                                            Text(
                                                                          "${listAttachmentItem[item].path}",
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          softWrap:
                                                                              true,
                                                                          maxLines:
                                                                              1,
                                                                          style:
                                                                              TextStyle(fontSize: 14),
                                                                        ),
                                                                        trailing: isAccess ==
                                                                                false
                                                                            ? Icon(Icons.lock)
                                                                            : ButtonTheme(
                                                                                minWidth: 0,
                                                                                height: 0,
                                                                                child: FlatButton(
                                                                                    padding: EdgeInsets.all(0),
                                                                                    onPressed: () {
                                                                                      showDialog(
                                                                                        context: context,
                                                                                        builder: (BuildContext context) => AlertDialog(
                                                                                          title: Text('Peringatan!'),
                                                                                          content: Text("Apakah Anda Yakin?"),
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
                                                                                                setState(() {
                                                                                                  isCreate = true;
                                                                                                });
                                                                                                Navigator.pop(context);
                                                                                                deleteFile(item, listAttachmentItem[item].id);
                                                                                              },
                                                                                            )
                                                                                          ],
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                                    child: Icon(Icons.delete, color: Colors.red)),
                                                                              ),
                                                                      ),
                                                                    )),
                                                            ],
                                                          ),
                                                  ],
                                                ))
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
        ));
  }

  Widget errorView() {
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
                elevation: 0.5,
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

  void _openFileExplorer() async {
    if (_pickingType != FileType.CUSTOM || _hasValidMime) {
      try {
        File file = await FilePicker.getFile(type: FileType.ANY);
        setState(() {
          pathname = file.toString();
          fileImage = base64Encode(file.readAsBytesSync());
          filename = file.toString().split('/').last;
        });
      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }
      if (!mounted) return;
    }
  }

  void dialogAddPermision(iduser) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Pilih Hak Akses!'),
        content: RadioGroup(),
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
              _updatestatusMember(iduser);
            },
          )
        ],
      ),
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
}

class RadioGroup extends StatefulWidget {
  @override
  RadioGroupWidget createState() => RadioGroupWidget();
}

class RoleList {
  String name;
  int index;
  RoleList({this.name, this.index});
}

class RadioGroupWidget extends State {
  int id = 2;

  List<RoleList> fList = [
    RoleList(
      index: 2,
      name: "Admin",
    ),
    RoleList(
      index: 3,
      name: "Executor",
    ),
    RoleList(
      index: 4,
      name: "Viewer",
    )
  ];

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        child: Column(
          children: fList
              .map((data) => RadioListTile(
                    title: Text("${data.name}"),
                    groupValue: id,
                    value: data.index,
                    onChanged: (val) {
                      setState(() {
                        radioItem = data.name;
                        id = data.index;
                        idChooseRole = data.index;
                      });
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
