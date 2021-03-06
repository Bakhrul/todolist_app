import 'package:todolist_app/src/pages/dashboard/home.dart';
import 'package:todolist_app/src/pages/manajamen_user/index.dart';
import 'package:todolist_app/src/pages/todolist/create_todo.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'dart:core';
import 'dart:io';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'manajemen_important/index.dart';
import 'manajemen_searching/index.dart';

String tokenType, accessToken;
String usernameprofile, emailprofile, imageprofile;
String emailStore, imageStore, namaStore, phoneStore, locationStore;
File imageDashboardProfile;
Map dataUser;
var datepickerfirst, datepickerlast;
Map<String, String> requestHeaders = Map();
String _tanggalawalProject, _tanggalakhirProject;
TextEditingController _namaprojectController = TextEditingController();
TextEditingController _tanggalawalProjectController = TextEditingController();
TextEditingController _tanggalakhirProjectController = TextEditingController();
TextEditingController _namaCategoryController = TextEditingController();

class Dashboard extends StatefulWidget {
  Dashboard({Key key, this.title}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  ProgressDialog progressApiAction;
  var indexColor = 0;
  bool isCheckVersion = true;

  @override
  void initState() {
    _tanggalawalProject = 'kosong';
    _tanggalakhirProject = 'kosong';
    datepickerfirst = FocusNode();
    getHeaderHTTP();
    _getStoreData();
    datepickerlast = FocusNode();
    super.initState();
  }

  PageController _myPage = PageController(initialPage: 0);

  _getStoreData() async {
    DataStore user = new DataStore();
    String namaRawUser = await user.getDataString('name');
    String emailRawUser = await user.getDataString('email');
    String phoneRawUser = await user.getDataString('phone');
    String imageRawUser = await user.getDataString('image');
    String locationRawUser = await user.getDataString('location');

    setState(() {
      imageDashboardProfile = null;
      namaStore = namaRawUser;
      emailStore = emailRawUser;
      phoneStore = phoneRawUser;
      imageStore = imageRawUser;
      locationStore = locationRawUser;
    });
  }

  void dispose() {
    super.dispose();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
    if (isCheckVersion == true) {
      return checkVersion();
    } else {
      return getDataProject();
    }
  }

  Future<List<List>> checkVersion() async {
    print('start cek versi');
    try {
      setState(() {
        isLoading = true;
      });
      final participant = await http.get(
          url('api/checkversion/${versionNumber.toInt()}'),
          headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var version = listParticipantToJson;
        if (version == 'Warning') {
          showModalVersionWarning(context);
        } else if (version == 'Expired') {
          showModalVersionDanger(context);
        }
        getDataProject();
        setState(() {
          isCheckVersion = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        print('eror cek versi');
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('eororor $e');
    }
    return null;
  }

  Future<List<List>> getDataProject() async {
    setState(() {
      isLoading = true;
      isError = false;
      isFilter = false;
      isErrorFilter = false;
      listProject.clear();
      listProject = [];
    });
    listProject.clear();
    listProject = [];
    try {
      final participant =
          await http.get(url('api/dashboard'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        setState(() {
          listProject.clear();
          listProject = [];
        });
        listProject.clear();
        listProject = [];
        var listParticipantToJson = json.decode(participant.body);
        var project = listParticipantToJson['project'];
        print(project);

        for (var i in project) {
          Project participant = Project(
            id: i['id'],
            title: i['title'].toString(),
            membertotal: i['member_total'],
            listMember: i['members'],
            percent: i['percent'].toString(),
            start: i['created_date'].toString(),
          );

          listProject.add(participant);
        }

        return getDataToDo();
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('$e');
    }
    return null;
  }

  Future<List<List>> getDataToDo() async {
    setState(() {
      listTodo.clear();
      listTodo = [];
      isLoading = true;
      isFilter = false;
      isErrorFilter = false;
    });
    listTodo.clear();
    listTodo = [];
    try {
      final participant = await http.get(url('api/todo/$currentFilter'),
          headers: requestHeaders);

      if (participant.statusCode == 200) {
        setState(() {
          listTodo.clear();
          listTodo = [];
        });
        listTodo.clear();
        listTodo = [];
        var listParticipantToJson = json.decode(participant.body);
        var todos = listParticipantToJson['todo'];
        for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              statuspinned: i['statuspinned'].toString(),
              allday: i['allday'],
              statusProgress: i['statusprogress'],
              coloredProgress: i['statusprogress'] == 'compleshed'
                  ? Colors.green
                  : i['statusprogress'] == 'overdue'
                      ? Colors.red
                      : i['statusprogress'] == 'pending'
                          ? Colors.grey
                          : i['statusprogress'] == 'working'
                              ? Colors.blue
                              : Colors.white);

          listTodo.add(todo);
        }

        setState(() {
          isLoading = false;
          isError = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
        return null;
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      debugPrint('$e');
      setState(() {
        isLoading = false;
        isError = true;
        isFilter = false;
        isErrorFilter = false;
      });
    }
    return null;
  }

  void _showmodalChooseTodo() {
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
                Container(
                    width: double.infinity,
                    height: 50.0,
                    child: RaisedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TodoList()));
                        },
                        color: primaryAppBarColor,
                        textColor: Colors.white,
                        disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                        disabledTextColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        child: Text("Buat ToDo",
                            style: TextStyle(color: Colors.white)))),
                Container(
                    margin: EdgeInsets.only(top: 15.0),
                    decoration: BoxDecoration(
                        border: Border(
                      right: BorderSide(
                        color: Colors.green,
                        width: 1.0,
                      ),
                      left: BorderSide(
                        color: Colors.green,
                        width: 1.0,
                      ),
                      top: BorderSide(
                        color: Colors.green,
                        width: 1.0,
                      ),
                      bottom: BorderSide(
                        color: Colors.green,
                        width: 1.0,
                      ),
                    )),
                    width: double.infinity,
                    height: 50.0,
                    child: RaisedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          _showmodalcreateProject();
                        },
                        color: Colors.green,
                        elevation: 0,
                        textColor: Colors.white,
                        disabledColor: Colors.green[400],
                        disabledTextColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        child: Text("Buat Project",
                            style: TextStyle(color: Colors.white)))),
                Container(
                    margin: EdgeInsets.only(top: 15.0),
                    decoration: BoxDecoration(
                        border: Border(
                      right: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                      left: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                      top: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                      bottom: BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                    )),
                    width: double.infinity,
                    height: 50.0,
                    child: RaisedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          _showModalCreateCategory();
                        },
                        color: Colors.blue,
                        elevation: 0,
                        textColor: Colors.white,
                        disabledColor: Colors.blue,
                        disabledTextColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        child: Text("Buat Kategori",
                            style: TextStyle(color: Colors.white)))),
              ],
            ),
          );
        });
  }

  void _showModalCreateCategory() {
    setState(() {
      _namaCategoryController.text = '';
    });
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 200.0 + MediaQuery.of(context).viewInsets.bottom,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                right: 15.0,
                left: 15.0,
                top: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(bottom: 20.0, top: 20.0),
                    child: TextField(
                      controller: _namaCategoryController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(
                            top: 5, bottom: 5, left: 10, right: 10),
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan Nama Kategori',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    )),
                Center(
                    child: Container(
                        width: double.infinity,
                        height: 45.0,
                        child: RaisedButton(
                            onPressed: () async {
                              if (_namaCategoryController.text == '') {
                                Fluttertoast.showToast(
                                    msg: 'Nama Kategori tidak boleh kosong');
                              } else {
                                _tambahcategory();
                              }
                            },
                            color: primaryAppBarColor,
                            textColor: Colors.white,
                            disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                            disabledTextColor: Colors.white,
                            splashColor: Colors.blueAccent,
                            child: Text("Tambah Kategori",
                                style: TextStyle(color: Colors.white)))))
              ],
            ),
          );
        });
  }

  void _showmodalcreateProject() {
    setState(() {
      _namaprojectController.text = '';
      _tanggalawalProject = 'kosong';
      _tanggalawalProject = 'kosong';
      _tanggalawalProjectController.text = '';
      _tanggalakhirProjectController.text = '';
    });
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return SingleChildScrollView(
            child: Container(
              height: 330.0 + MediaQuery.of(context).viewInsets.bottom,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  right: 15.0,
                  left: 15.0,
                  top: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                      margin: EdgeInsets.only(bottom: 20.0, top: 20.0),
                      child: TextField(
                        controller: _namaprojectController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan Nama Project',
                          hintStyle:
                              TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      )),
                  Container(
                    margin: EdgeInsets.only(
                      bottom: 15.0,
                    ),
                    child: DateTimeField(
                      controller: _tanggalawalProjectController,
                      readOnly: true,
                      format: DateFormat('dd-MM-yyy'),
                      focusNode: datepickerfirst,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(
                            top: 5, bottom: 5, left: 10, right: 10),
                        border: OutlineInputBorder(),
                        hintText: 'Tanggal Dimulainya Project',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      onShowPicker: (context, currentValue) {
                        return showDatePicker(
                            firstDate: DateTime(1900),
                            context: context,
                            initialDate: _tanggalawalProjectController.text !=
                                    ''
                                ? DateFormat("dd-MM-yyyy").parse(
                                    "${_tanggalawalProjectController.text}")
                                : _tanggalakhirProjectController.text == ''
                                    ? DateTime.now()
                                    : DateFormat("dd-MM-yyyy").parse(
                                        "${_tanggalakhirProjectController.text}"),
                            lastDate: _tanggalakhirProjectController.text == ''
                                ? DateTime(2100)
                                : DateFormat("dd-MM-yyyy").parse(
                                    "${_tanggalakhirProjectController.text}"));
                      },
                      onChanged: (ini) {
                        setState(() {
                          // _tanggalawalProject =
                          //     ini == null ? 'kosong' : ini.toString();
                        });
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 25.0),
                    child: DateTimeField(
                      controller: _tanggalakhirProjectController,
                      readOnly: true,
                      format: DateFormat('dd-MM-yyy'),
                      focusNode: datepickerlast,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.only(
                            top: 5, bottom: 5, left: 10, right: 10),
                        hintText: 'Tanggal Berakhirnya Project',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      onShowPicker: (context, currentValue) {
                        DateFormat inputFormat = DateFormat("dd-MM-yyyy");
                        return showDatePicker(
                          context: context,
                            firstDate: _tanggalawalProjectController.text == ''
                                ? DateTime(2000)
                                : inputFormat.parse(
                                    "${_tanggalawalProjectController.text}"),
                            initialDate: _tanggalakhirProjectController.text ==
                                    ''
                                ? _tanggalawalProjectController.text == ''
                                    ? DateTime.now()
                                    : inputFormat.parse(
                                        "${_tanggalawalProjectController.text}")
                                : inputFormat.parse(
                                    "${_tanggalakhirProjectController.text}"),
                            lastDate: DateTime(2100));
                      },
                      onChanged: (ini) {
                        if (_tanggalawalProjectController.text == '') {
                          _tanggalawalProjectController.text =
                              _tanggalakhirProjectController.text;
                        }
                      },
                    ),
                  ),
                  Center(
                      child: Container(
                          width: double.infinity,
                          height: 45.0,
                          child: RaisedButton(
                              onPressed: () async {
                                if (_namaprojectController.text == '') {
                                  Fluttertoast.showToast(
                                      msg: 'Nama project tidak boleh kosong');
                                } else if (_tanggalawalProjectController.text ==
                                    '') {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Tanggal dimulanya project tidak boleh kosong');
                                } else if (_tanggalakhirProjectController
                                        .text ==
                                    '') {
                                  Fluttertoast.showToast(
                                      msg:
                                          'Tanggal berakhirnya project tidak boleh kosong');
                                } else {
                                  _tambahProject();
                                }
                              },
                              color: primaryAppBarColor,
                              textColor: Colors.white,
                              disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                              disabledTextColor: Colors.white,
                              splashColor: Colors.blueAccent,
                              child: Text("Buat Project Sekarang",
                                  style: TextStyle(color: Colors.white)))))
                ],
              ),
            ),
          );
        });
  }

  void _tambahcategory() async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addadminevent = await http
          .post(url('api/tambah_kategori'), headers: requestHeaders, body: {
        'nama_kategori': _namaCategoryController.text,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: "Berhasil, Menambahkan Kategori");
        } else if (addpesertaJson['status'] == 'sudah ada') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: "Kategori Tersebut Sudah Ada");
        }
      } else {
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {});
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

  void _tambahProject() async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      final addadminevent = await http
          .post(url('api/create_project'), headers: requestHeaders, body: {
        'nama_project': _namaprojectController.text,
        'time_end':
            _tanggalakhirProjectController.text == '' ? null : _tanggalakhirProjectController.text,
        'time_start':
            _tanggalawalProjectController.text == '' ? null : _tanggalawalProjectController.text,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: "Berhasil.");
          getDataProject();
        }
      } else {
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {});
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

  Future<Null> removeSharedPrefs() async {
    DataStore dataStore = new DataStore();
    dataStore.clearData();
  }

  Widget appBarTitle = Text(
    "Dashboard",
    style: TextStyle(fontSize: 16),
  );
  Icon notifIcon = Icon(
    Icons.more_vert,
    color: Colors.white,
  );

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
        backgroundColor: Colors.white,
        // key: _scaffoldKeyDashboard,
        // appBar: indexColor == 0
        //     ? new AppBar(
        //         backgroundColor: primaryAppBarColor,
        //         iconTheme: IconThemeData(
        //           color: Colors.white,
        //         ),
        //         title: new Text(
        //           "Dashboard",
        //           style: TextStyle(
        //             color: Colors.white,
        //             fontSize: 16,
        //           ),
        //         ),
        //         automaticallyImplyLeading: false,
        //       )
        //     : null,
        body: PageView(
          controller: _myPage,
          onPageChanged: (int) {
            print('Page Changes to index $int');
            setState(() {
              indexColor = int;
            });
          },
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(0),
              child: Container(
                child: Home(),
              ),
            ),
            Center(
              child: Container(
                child: ManajemenTodoImportant(),
              ),
            ),
            Center(
              child: Container(
                child: ManajemenSerachTodo(),
              ),
            ),
            Center(
              child: Container(
                child: ManajemenUser(),
              ),
            )
          ],
          physics:
              NeverScrollableScrollPhysics(), // Comment this if you need to use Swipe.
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: indexColor != 0
            ? null
            : FloatingActionButton(
                onPressed: () {
                  _showmodalChooseTodo();
                },
                child: Icon(Icons.add),
                backgroundColor: primaryAppBarColor),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: IconButton(
                  icon: Icon(
                    Icons.home,
                    color: indexColor == 0 ? primaryAppBarColor : Colors.grey,
                  ),
                  tooltip: "Beranda",
                  onPressed: () {
                    setState(() {
                      _myPage.jumpToPage(0);
                    });
                  },
                ),
              ),
              Container(
                margin: indexColor != 0
                    ? EdgeInsets.all(0)
                    : EdgeInsets.only(right: 30.0),
                child: IconButton(
                  icon: Icon(
                    Icons.star_border,
                    color: indexColor == 1 ? primaryAppBarColor : Colors.grey,
                  ),
                  tooltip: "Favorite",
                  onPressed: () {
                    setState(() {
                      _myPage.jumpToPage(1);
                    });
                  },
                ),
              ),
              Container(
                margin: indexColor != 0
                    ? EdgeInsets.all(0)
                    : EdgeInsets.only(left: 30.0),
                child: IconButton(
                  icon: Icon(
                    Icons.search,
                    color: indexColor == 2 ? primaryAppBarColor : Colors.grey,
                  ),
                  tooltip: "Cari",
                  onPressed: () {
                    setState(() {
                      _myPage.jumpToPage(2);
                    });
                  },
                ),
              ),
              Container(
                child: IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: indexColor == 3 ? primaryAppBarColor : Colors.grey,
                  ),
                  tooltip: "Profile",
                  color: indexColor == 3 ? primaryAppBarColor : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _myPage.jumpToPage(3);
                    });
                  },
                ),
              )
            ],
          ),
          shape: CircularNotchedRectangle(),
        )
        // ),
        );
  }

  void showModalVersionWarning(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            contentPadding: EdgeInsets.only(top: 0.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 60,
                      decoration: new BoxDecoration(
                          color: Colors.orange,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(8.0),
                            topRight: const Radius.circular(8.0),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 40,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Version Update",
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Divider(),
                    Padding(
                        padding: EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 8.0),
                        child: Text(
                          "Versi Terbaru Telah Tersedia",
                          style: TextStyle(fontSize: 14),
                        )),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Todolist menyarankan anda untuk mengupdate ke versi terbaru. Anda dapat tetap menggunakan aplikasi ini saat mendownload update",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey, height: 1.5),
                          textAlign: TextAlign.justify,
                        )),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () {
                            // Navigator.pushReplacementNamed(context, "/dashboard");
                            Navigator.pop(context);
                          },
                          child: Text("CANCEL",
                              style: TextStyle(color: Colors.black54)),
                        ),
                        FlatButton(
                          onPressed: () {},
                          child: Text("UPDATE",
                              style: TextStyle(color: primaryAppBarColor)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  void showModalVersionDanger(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8.0))),
            contentPadding: EdgeInsets.only(top: 0.0),
            content: SingleChildScrollView(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 60,
                      decoration: new BoxDecoration(
                          color: Colors.red,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(8.0),
                            topRight: const Radius.circular(8.0),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 40,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "Version Update",
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Divider(),
                    Padding(
                        padding: EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 8.0),
                        child: Text(
                          "Versi Terbaru Telah Tersedia",
                          style: TextStyle(fontSize: 14),
                        )),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Todolist menyarankan anda untuk mengupdate ke versi terbaru. Versi yang anda gunakan telah kadaluarsa",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey, height: 1.5),
                          textAlign: TextAlign.justify,
                        )),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          onPressed: () {},
                          child: Text("UPDATE",
                              style: TextStyle(color: primaryAppBarColor)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
