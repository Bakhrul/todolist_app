import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:todolist_app/src/pages/dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:todolist_app/src/model/Todo.dart';
import 'package:todolist_app/src/model/Project.dart';
import 'package:todolist_app/src/pages/todolist/detail_todo.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../manajemen_project/detail_project.dart';
import '../todolist/detail_todo.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

final Widget placeholder = Container(color: Colors.grey);
TextEditingController _namaprojectController = TextEditingController();
String emailStore, imageStore, namaStore, phoneStore, locationStore;
TextEditingController _tanggalawalProjectController = TextEditingController();
String _tanggalawalProject, _tanggalakhirProject;
TextEditingController _tanggalakhirProjectController = TextEditingController();
String imageData;
List<T> map<T>(List list, Function handler) {
  List<T> result = [];
  for (var i = 0; i < list.length; i++) {
    result.add(handler(i, list[i]));
  }

  return result;
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ProgressDialog progressApiAction;
  final List<Color> listColor = [Colors.grey, Colors.red, Colors.blue];
  List<Project> listProject = [];
  bool isFilter, isErrorFilter, isLoading, isError;
  String tokenType, accessToken;
  Map<String, String> requestHeaders = Map();
  List<Todo> listTodo = [];
  String namaUser;

  void getDataUser() async {
    DataStore user = new DataStore();
    String namaRawUser = await user.getDataString('name');
    String imageStore = await user.getDataString('photo');
    setState(() {
      imageData = imageStore;
      namaUser = namaRawUser;
    });
  }

  List listFilter = [
    {'index': "1", 'name': "Molor"},
    {'index': "2", 'name': "Hari Ini"},
    {'index': "3", 'name': "Besok"},
    {'index': "4", 'name': "Lusa"},
    {'index': "5", 'name': "Minggu Ini"},
    {'index': "6", 'name': "Bulan Ini"},
    {'index': "7", 'name': "Pending"}
  ];

  int currentFilter = 1;

  @override
  void initState() {
    super.initState();
    _tanggalawalProject = 'kosong';
    _tanggalakhirProject = 'kosong';
    getDataProject();
    getDataUser();
    isLoading = true;
    _getStoreData();
  }

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
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: "Berhasil, Silahkan refresh halaman ini");
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

  Future<List<List>> getDataProject() async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      isLoading = true;
      isError = false;
      listProject.clear();
    });
    try {
      final participant =
          await http.get(url('api/dashboard'), headers: requestHeaders);

      if (participant.statusCode == 200) {
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
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listTodo.clear();
      listTodo = [];
      isLoading = true;
    });
    try {
      final participant = await http.get(url('api/todo/$currentFilter'),
          headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var todos = listParticipantToJson;
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

  void filterDataTodo(index) async {
    var storage = new DataStore();
    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;
    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';

    setState(() {
      listTodo.clear();
      listTodo = [];
      isFilter = true;
    });
    try {
      final participant =
          await http.get(url('api/todo/$index'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var todos = listParticipantToJson;
        // print(todos);
        for (var i in todos) {
          Todo todo = Todo(
              id: i['id'],
              title: i['title'].toString(),
              timeend: i['end'].toString(),
              timestart: i['start'].toString(),
              statuspinned: i['statuspinned'].toString(),
              allday: i['allday'],
              coloredProgress: i['statusprogress'] == 'compleshed'
                  ? Colors.green
                  : i['statusprogress'] == 'overdue'
                      ? Colors.red
                      : i['statusprogress'] == 'pending'
                          ? Colors.grey
                          : Colors.white);

          listTodo.add(todo);
        }

        setState(() {
          isFilter = false;
          isErrorFilter = false;
          isFilter = false;
          isErrorFilter = false;
        });
      } else if (participant.statusCode == 401) {
        Fluttertoast.showToast(
            msg: "Token Telah Kadaluwarsa, Silahkan Login Kembali");
        setState(() {
          isFilter = false;
          isErrorFilter = true;
          isFilter = false;
          isErrorFilter = false;
        });
      } else {
        setState(() {
          isFilter = false;
          isErrorFilter = true;
          isFilter = false;
          isErrorFilter = false;
        });
        print(participant.body);
      }
    } on TimeoutException catch (_) {
      setState(() {
        isLoading = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      Fluttertoast.showToast(msg: "Timed out, Try again");
    } catch (e) {
      setState(() {
        isLoading = false;
        isErrorFilter = true;
        isFilter = false;
        isErrorFilter = false;
      });
      debugPrint('$e');
    }
    return null;
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
                      DateFormat inputFormat = DateFormat("dd-MM-yyyy");
                      DateTime dateTime = inputFormat
                          .parse("${_tanggalawalProjectController.text}");

                      return showDatePicker(
                          firstDate: dateTime,
                          context: context,
                          initialDate: dateTime,
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
    return RefreshIndicator(
      onRefresh: getDataProject,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SafeArea(
              child: Stack(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                            color: primaryAppBarColor,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(100.0),
                            )),
                        height: 220.0,
                        margin: EdgeInsets.only(bottom: 0.0),
                      ),
                      Container(
                        margin:
                            EdgeInsets.only(top: 25.0, left: 15.0, right: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Hi, $namaStore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                                margin: EdgeInsets.only(left: 20),
                                height: 40,
                                width: 40,
                                child: ClipOval(
                                    child: FadeInImage.assetNetwork(
                                        fit: BoxFit.cover,
                                        placeholder: 'images/imgavatar.png',
                                        image: imageData == null ||
                                                imageData == ''
                                            ? url('assets/images/imgavatar.png')
                                            : url(
                                                'storage/profile/$imageData'))))

                            // :Text("uyee"),
                          ],
                        ),
                      ),
                      isError == true
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(
                                        3, 3), // changes position of shadow
                                  ),
                                ],
                                color: Colors.white,
                              ),
                              margin: EdgeInsets.only(
                                  top: 100.0,
                                  left: 15.0,
                                  bottom: 40.0,
                                  right: 15.0),
                              padding: EdgeInsets.all(15.0),
                              width: double.infinity,
                              child: Column(
                                children: <Widget>[
                                  new Container(
                                    width: 100.0,
                                    height: 100.0,
                                    child:
                                        Image.asset("images/system-eror.png"),
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
                                        top: 15.0,
                                        left: 15.0,
                                        right: 15.0,
                                        bottom: 15.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: RaisedButton(
                                        elevation: 0,
                                        color: Colors.white,
                                        textColor: primaryAppBarColor,
                                        disabledColor: Colors.grey,
                                        disabledTextColor: Colors.black,
                                        padding: EdgeInsets.all(15.0),
                                        onPressed: () async {
                                          getDataProject();
                                        },
                                        child: Text(
                                          "Muat Ulang Halaman",
                                          style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      isError == true
                          ? Container()
                          : Container(
                              margin: EdgeInsets.only(top: 100.0, left: 15.0),
                              child: Text(
                                'Project Board',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16),
                              ),
                            ),
                      isError == true
                          ? Container()
                          : isLoading == true
                              ? loadingProject()
                              : listProject.length == 0
                                  ? Container(
                                      margin: EdgeInsets.only(
                                        right: 15.0,
                                        bottom: 15.0,
                                        left: 15.0,
                                        top: 135.0,
                                      ),
                                      child: Container(
                                          padding: EdgeInsets.only(
                                              top: 15.0,
                                              left: 15.0,
                                              right: 15.0,
                                              bottom: 15.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.1),
                                                spreadRadius: 2,
                                                blurRadius: 2,
                                                offset: Offset(3,
                                                    3), // changes position of shadow
                                              ),
                                            ],
                                          ),
                                          height: 160.0,
                                          width: 300.0,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Container(
                                                height: 80.0,
                                                child: Row(
                                                  children: <Widget>[
                                                    Container(
                                                        width: 60.0,
                                                        height: 60.0,
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                              'images/empty-project.png'),
                                                        )),
                                                    Expanded(
                                                        flex: 9,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 10.0),
                                                          child: Text(
                                                            'Kamu Belum Memiliki Project Sama Sekali, Buat Sekarang Yuk',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              height: 1.5,
                                                            ),
                                                          ),
                                                        ))
                                                  ],
                                                ),
                                              ),
                                              Divider(),
                                              GestureDetector(
                                                onTap: () async {
                                                  _showmodalcreateProject();
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                      'Buat Project Sekarang',
                                                      style: TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                              ),
                                            ],
                                          )))
                                  : Container(
                                      margin: EdgeInsets.only(
                                          top: 135.0, left: 15.0),
                                      padding: EdgeInsets.only(bottom: 10.0),
                                      child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: listProject
                                                .map(
                                                    (Project item) =>
                                                        GestureDetector(
                                                          onTap: () async {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (context) => ManajemenDetailProjectAll(
                                                                        idproject:
                                                                            item
                                                                                .id,
                                                                        namaproject:
                                                                            item.title)));
                                                          },
                                                          child: Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    right: 15.0,
                                                                    bottom:
                                                                        15.0),
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: 15.0,
                                                                      left:
                                                                          15.0,
                                                                      right:
                                                                          15.0,
                                                                      bottom:
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
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        bottom:
                                                                            15.0),
                                                                    child: Text(
                                                                      item.title == null ||
                                                                              item.title ==
                                                                                  ''
                                                                          ? 'Project tidak diketahui'
                                                                          : item
                                                                              .title,
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black,
                                                                          fontWeight: FontWeight
                                                                              .w400,
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                  ),
                                                                  Stack(
                                                                    children: <
                                                                        Widget>[
                                                                      Container(
                                                                        color: Colors
                                                                            .transparent,
                                                                        height:
                                                                            45.0,
                                                                      ),
                                                                      for (var i =
                                                                              0;
                                                                          i < item.listMember.length;
                                                                          i++)
                                                                        Positioned(
                                                                          top:
                                                                              0,
                                                                          left: i == 0
                                                                              ? 0
                                                                              : i == 1 ? 25.0 : i == 2 ? 50.0 : i == 3 ? 75.0 : i == 4 ? 100.0 : i == 5 ? 125.0 : 0.0,
                                                                          child: Container(
                                                                              height: 35,
                                                                              width: 35,
                                                                              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.0), borderRadius: BorderRadius.circular(100.0)),
                                                                              child: ClipOval(child: FadeInImage.assetNetwork(placeholder: 'images/loading.gif', image: url('assets/images/imgavatar.png')))),
                                                                        ),
                                                                      item.membertotal >
                                                                              5
                                                                          ? Positioned(
                                                                              left: 120.0,
                                                                              child: Container(
                                                                                alignment: Alignment.center,
                                                                                child: Text(
                                                                                  '+ ' + (item.membertotal - item.listMember.length).toString(),
                                                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                                                                ),
                                                                                width: 35.0,
                                                                                height: 35.0,
                                                                                decoration: BoxDecoration(color: primaryAppBarColor, border: Border.all(color: Colors.white, width: 2.0), borderRadius: BorderRadius.circular(100.0)),
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                    ],
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsets.only(
                                                                        bottom:
                                                                            5.0,
                                                                        top:
                                                                            10.0,
                                                                        left: 0,
                                                                        right:
                                                                            15.0),
                                                                    child:
                                                                        new LinearPercentIndicator(
                                                                      // width: double.infinity,
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              0),
                                                                      width:
                                                                          150.0,
                                                                      animation:
                                                                          true,
                                                                      lineHeight:
                                                                          6.0,
                                                                      animationDuration:
                                                                          2500,
                                                                      percent:
                                                                          double.parse(item.percent) /
                                                                              100,
                                                                      linearStrokeCap:
                                                                          LinearStrokeCap
                                                                              .butt,
                                                                      progressColor:
                                                                          Colors
                                                                              .blue,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    margin: EdgeInsets
                                                                        .only(
                                                                            top:
                                                                                5.0),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: <
                                                                          Widget>[
                                                                        Container(
                                                                          child:
                                                                              Text(
                                                                            '${item.percent}% Complete',
                                                                            style: TextStyle(
                                                                                color: Colors.grey,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.w500),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          child:
                                                                              Row(
                                                                            children: <Widget>[
                                                                              Icon(
                                                                                Icons.calendar_today,
                                                                                size: 12,
                                                                                color: Colors.grey,
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.only(left: 5.0),
                                                                                child: Text(
                                                                                  item.start == null ? 'Tidak Diketahui' : DateFormat('dd MM yyyy').format(DateTime.parse(item.start)),
                                                                                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      // Text('80% Complete'),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15.0),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .grey
                                                                        .withOpacity(
                                                                            0.1),
                                                                    spreadRadius:
                                                                        2,
                                                                    blurRadius:
                                                                        2,
                                                                    offset: Offset(
                                                                        3,
                                                                        3), // changes position of shadow
                                                                  ),
                                                                ],
                                                              ),
                                                              height: 160.0,
                                                              width: 260.0,
                                                              // margin: EdgeInsets.only(right: 15.0),
                                                            ),
                                                          ),
                                                        ))
                                                .toList(),
                                          )),
                                    ),
                    ],
                  )
                ],
              ),
            ),
            isError == true
                ? Container()
                : isLoading == true
                    ? Container(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              margin: EdgeInsets.only(top: 10.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 0.0),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300],
                                highlightColor: Colors.grey[100],
                                child: Row(
                                  children: [0, 1, 2, 3, 4]
                                      .map((_) => Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5.0)),
                                            ),
                                            margin:
                                                EdgeInsets.only(right: 15.0),
                                            width: 120.0,
                                            height: 20.0,
                                          ))
                                      .toList(),
                                ),
                              ),
                            )))
                    : Container(
                        margin: EdgeInsets.only(left: 8.0, bottom: 8),
                        color: Colors.transparent,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                for (var x in listFilter)
                                  Container(
                                      margin: EdgeInsets.only(right: 10.0),
                                      child: ButtonTheme(
                                        minWidth: 0.0,
                                        height: 0,
                                        child: RaisedButton(
                                          color: currentFilter ==
                                                  int.parse(x['index'])
                                              ? primaryAppBarColor
                                              : Colors.grey[100],
                                          elevation: 0.0,
                                          highlightColor: Colors.transparent,
                                          highlightElevation: 0.0,
                                          padding: EdgeInsets.only(
                                              top: 7.0,
                                              left: 15.0,
                                              right: 15.0,
                                              bottom: 7.0),
                                          onPressed: () {
                                            setState(() {
                                              currentFilter =
                                                  int.parse(x['index']);
                                              if (isFilter == true) {
                                              } else {
                                                filterDataTodo(
                                                    int.parse(x['index']));
                                              }
                                            });
                                          },
                                          child: Text(
                                            x['name'],
                                            style: TextStyle(
                                                color: currentFilter ==
                                                        int.parse(x['index'])
                                                    ? Colors.white
                                                    : Colors.black54,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      18.0),
                                              side: BorderSide(
                                                color: Colors.transparent,
                                              )),
                                        ),
                                      )),
                              ]),
                        ),
                      ),
            isError == true
                ? Container()
                : isLoading == true
                    ? Container()
                    : Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 10.0, top: 5.0, bottom: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(('List To Do').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
            isError == true
                ? Container()
                : isLoading == true || isFilter == true
                    ? listLoadingTodo()
                    : isErrorFilter == true
                        ? errorSystemFilter(context)
                        : listTodo.length == 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Column(children: <Widget>[
                                  new Container(
                                    width: 100.0,
                                    height: 100.0,
                                    child: Image.asset("images/todo_icon2.png"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20.0,
                                        left: 25.0,
                                        right: 25.0,
                                        bottom: 35.0),
                                    child: Center(
                                      child: Text(
                                        "To Do Yang Anda Cari Tidak Ditemukan",
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ]),
                              )
                            : Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: <Widget>[
                                      for (var x in listTodo)
                                        InkWell(
                                          onTap: () async {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ManajemenDetailTodo(
                                                          idtodo: x.id,
                                                          namatodo: x.title,
                                                        )));
                                          },
                                          child: Container(
                                            child: Card(
                                                elevation: 0.5,
                                                margin: EdgeInsets.only(
                                                    top: 5.0,
                                                    bottom: 5.0,
                                                    left: 0.0,
                                                    right: 0.0),
                                                child: ClipPath(
                                                  clipper: ShapeBorderClipper(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3))),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        border: Border(
                                                            right: BorderSide(
                                                                color: x
                                                                    .coloredProgress,
                                                                width: 5))),
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
                                                          child: Container(
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
                                                                    width: 2.0),
                                                                borderRadius:
                                                                    BorderRadius.all(
                                                                        Radius.circular(
                                                                            100.0) //                 <--- border radius here
                                                                        ),
                                                                color:
                                                                    primaryAppBarColor,
                                                              ),
                                                              child: Text(
                                                                '${x.title[0].toUpperCase()}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              )),
                                                        ),
                                                      ),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          ButtonTheme(
                                                            minWidth: 0.0,
                                                            child: FlatButton(
                                                                onPressed:
                                                                    () async {
                                                                  try {
                                                                    final actionPinnedTodo = await http.post(
                                                                        url(
                                                                            'api/actionpinned_todo'),
                                                                        headers:
                                                                            requestHeaders,
                                                                        body: {
                                                                          'todolist': x
                                                                              .id
                                                                              .toString(),
                                                                        });

                                                                    if (actionPinnedTodo
                                                                            .statusCode ==
                                                                        200) {
                                                                      var actionPinnedTodoJson =
                                                                          json.decode(
                                                                              actionPinnedTodo.body);
                                                                      if (actionPinnedTodoJson[
                                                                              'status'] ==
                                                                          'tambah') {
                                                                        setState(
                                                                            () {
                                                                          x.statuspinned = x
                                                                              .id
                                                                              .toString();
                                                                        });
                                                                      } else if (actionPinnedTodoJson[
                                                                              'status'] ==
                                                                          'hapus') {
                                                                        setState(
                                                                            () {
                                                                          x.statuspinned =
                                                                              null;
                                                                        });
                                                                      }
                                                                    } else {
                                                                      print(actionPinnedTodo
                                                                          .body);
                                                                    }
                                                                  } on TimeoutException catch (_) {
                                                                    Fluttertoast
                                                                        .showToast(
                                                                            msg:
                                                                                "Timed out, Try again");
                                                                  } catch (e) {
                                                                    print(e);
                                                                  }
                                                                },
                                                                color: Colors
                                                                    .white,
                                                                child: Icon(
                                                                  Icons
                                                                      .star_border,
                                                                  color: x.statuspinned == null ||
                                                                          x.statuspinned ==
                                                                              'null'
                                                                      ? Colors
                                                                          .grey
                                                                      : Colors
                                                                          .orange,
                                                                )),
                                                          ),
                                                        ],
                                                      ),
                                                      title: Text(
                                                          x.title == '' ||
                                                                  x.title ==
                                                                      null
                                                              ? 'To Do Tidak Diketahui'
                                                              : x.title,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          softWrap: true,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                      subtitle: Text(
                                                          DateFormat(x.allday >
                                                                          0
                                                                      ? 'd/MM/y'
                                                                      : 'd/MM/y HH:mm')
                                                                  .format(DateTime
                                                                      .parse(
                                                                          "${x.timestart}"))
                                                                  .toString() +
                                                              ' - ' +
                                                              DateFormat(x.allday >
                                                                          0
                                                                      ? 'd/MM/y'
                                                                      : 'd/MM/y HH:mm')
                                                                  .format(DateTime
                                                                      .parse(
                                                                          "${x.timeend}"))
                                                                  .toString(),
                                                          softWrap: true,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1),
                                                    ),
                                                  ),
                                                )),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
          ],
        ),
      ),
    );
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }

  Widget errorSystemFilter(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
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
                filterDataTodo(int.parse(currentFilter.toString()));
              },
              child: Text(
                "Muat Ulang Halaman",
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget listLoadingTodo() {
    return Container(
        margin: EdgeInsets.only(top: 20.0),
        child: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300],
            highlightColor: Colors.grey[100],
            child: Column(
              children: [0, 1, 2, 3, 4]
                  .map((_) => Padding(
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40.0,
                                  height: 40.0,
                                  color: Colors.white,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5.0),
                                      ),
                                      Container(
                                        width: 40.0,
                                        height: 8.0,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        )));
  }

  Widget loadingProject() {
    return Container(
      margin: EdgeInsets.only(top: 135.0, left: 15.0),
      padding: EdgeInsets.only(bottom: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < 5; i++)
              Container(
                margin: EdgeInsets.only(right: 15.0, bottom: 15.0),
                child: Container(
                  padding: EdgeInsets.only(
                      top: 15.0, left: 15.0, right: 15.0, bottom: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          color: Colors.white,
                          child: SingleChildScrollView(
                              child: Container(
                            width: double.infinity,
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey[300],
                              highlightColor: Colors.grey[100],
                              child: Column(
                                children: [
                                  0,
                                ]
                                    .map((_) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(5.0)),
                                              ),
                                              width: double.infinity,
                                              height: 10.0,
                                            ),
                                            Container(
                                              margin:
                                                  EdgeInsets.only(top: 15.0),
                                              child: Row(
                                                children: <Widget>[
                                                  for (int i = 0; i < 5; i++)
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          right: 5.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    100.0)),
                                                      ),
                                                      width: 35.0,
                                                      height: 35.0,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin:
                                                  EdgeInsets.only(top: 20.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(5.0)),
                                              ),
                                              width: double.infinity,
                                              height: 10.0,
                                            ),
                                            Container(
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(5.0)),
                                              ),
                                              width: 170.0,
                                              height: 10.0,
                                            ),
                                            Container(
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(5.0)),
                                              ),
                                              width: 170.0,
                                              height: 10.0,
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                          ))),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: Offset(3, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  height: 160.0,
                  width: 260.0,
                  // margin: EdgeInsets.only(right: 15.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
