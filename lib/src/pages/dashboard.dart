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
    return requestHeaders;
  }

  void _showmodalChooseTodo() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
            height: 170.0 + MediaQuery.of(context).viewInsets.bottom,
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
                          _showmodalcreateProject();
                        },
                        color: primaryAppBarColor,
                        textColor: Colors.white,
                        disabledColor: Color.fromRGBO(254, 86, 14, 0.7),
                        disabledTextColor: Colors.white,
                        splashColor: Colors.blueAccent,
                        child: Text("Buat Project",
                            style: TextStyle(color: Colors.white)))),
                Container(
                    margin: EdgeInsets.only(top: 15.0),
                    decoration: BoxDecoration(
                        border: Border(
                      right: BorderSide(
                        color: primaryAppBarColor,
                        width: 2.0,
                      ),
                      left: BorderSide(
                        color: primaryAppBarColor,
                        width: 2.0,
                      ),
                      top: BorderSide(
                        color: primaryAppBarColor,
                        width: 2.0,
                      ),
                      bottom: BorderSide(
                        color: primaryAppBarColor,
                        width: 2.0,
                      ),
                    )),
                    width: double.infinity,
                    height: 50.0,
                    child: RaisedButton(
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TodoList()));
                        },
                        color: Colors.white,
                        elevation: 0,
                        textColor: primaryAppBarColor,
                        disabledColor: Colors.white,
                        disabledTextColor: primaryAppBarColor,
                        splashColor: Colors.blueAccent,
                        child: Text("Buat Todo",
                            style: TextStyle(color: primaryAppBarColor)))),
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
          return Container(
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
                        hintStyle: TextStyle(fontSize: 12, color: Colors.black),
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
                    initialValue: _tanggalawalProject == 'kosong'
                        ? null
                        : DateTime.parse(_tanggalawalProject),
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
                          initialDate: DateTime.now(),
                          lastDate: DateTime(2100));
                    },
                    onChanged: (ini) {
                      setState(() {
                        _tanggalawalProject =
                            ini == null ? 'kosong' : ini.toString();
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
                    initialValue: _tanggalakhirProject == 'kosong'
                        ? null
                        : DateTime.parse(_tanggalakhirProject),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.only(
                          top: 5, bottom: 5, left: 10, right: 10),
                      hintText: 'Tanggal Berakhirnya Project',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    onShowPicker: (context, currentValue) {
                      return showDatePicker(
                          firstDate: DateTime(1900),
                          context: context,
                          initialDate: DateTime.now(),
                          lastDate: DateTime(2100));
                    },
                    onChanged: (ini) {
                      setState(() {
                        _tanggalakhirProject =
                            ini == null ? 'kosong' : ini.toString();
                      });
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
                              } else if (_tanggalakhirProjectController.text ==
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
          );
        });
  }

  void _tambahProject() async {
    Navigator.pop(context);
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addadminevent = await http
          .post(url('api/create_project'), headers: requestHeaders, body: {
        'nama_project': _namaprojectController.text,
        'time_end':
            _tanggalakhirProject == 'kosong' ? null : _tanggalakhirProject,
        'time_start':
            _tanggalawalProject == 'kosong' ? null : _tanggalawalProject,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {

          });
          Fluttertoast.showToast(msg: "Berhasil !");
        }
      } else {
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {

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
        appBar: new AppBar(
          backgroundColor: primaryAppBarColor,
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: new Text(
            "Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
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
              padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 4.0),
              child: Container(
                child: Home(),
              ),
            ),
            Center(
              child: Container(
                child: Text('Empty Body 1'),
              ),
            ),
            Center(
              child: Container(
                child: Text('Empty Body 2'),
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
        floatingActionButton: FloatingActionButton(
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
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: indexColor == 0 ? primaryAppBarColor : Colors.black,
                ),
                tooltip: "Beranda",
                onPressed: () {
                  setState(() {
                    _myPage.jumpToPage(0);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.star,color: Colors.grey,),
                tooltip: "Favorite",
              ),
              Text(''),
              Text(''),
              IconButton(
                icon: Icon(Icons.search,color: Colors.grey,),
                tooltip: "Cari",
              ),
              IconButton(
                icon: Icon(Icons.person,color: Colors.grey,),
                tooltip: "Profile",
                color: indexColor == 3 ? primaryAppBarColor : Colors.black,
                onPressed: () {
                  setState(() {
                    _myPage.jumpToPage(3);
                  });
                },
              )
            ],
          ),
          shape: CircularNotchedRectangle(),
        )
        // ),
        );
  }

  
}
