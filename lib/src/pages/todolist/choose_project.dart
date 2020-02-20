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
import 'package:todolist_app/src/model/Project.dart';
import 'package:shimmer/shimmer.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'create_todo.dart';

String tokenType, accessToken;
var datepickerfirst, datepickerlast;
bool focus;
List<Project> listProject = [];
bool isLoading, isError;
String _tanggalawalProject, _tanggalakhirProject;
Map<String, String> requestHeaders = Map();
var datepickerfirstProject, datepickerlastProject;
TextEditingController _controllerNamaProject = TextEditingController();
TextEditingController _controllerTanggalAwalProject = TextEditingController();
TextEditingController _controllerTanggalAkhirProject = TextEditingController();

enum PageMember {
  hapusMember,
  gantiStatusMember,
}

enum PageTodo {
  hapusTodo,
  gantistatusTodo,
}

class ChooseProjectAvailable extends StatefulWidget {
  ChooseProjectAvailable({Key key, this.title, this.idproject})
      : super(key: key);
  final String title;
  final int idproject;
  @override
  State<StatefulWidget> createState() {
    return _ChooseProjectAvailableState();
  }
}

class _ChooseProjectAvailableState extends State<ChooseProjectAvailable>
    with SingleTickerProviderStateMixin {
  final format = DateFormat("dd-MM-yyyy");
  DateTime timeReplacement;
  ProgressDialog progressApiAction;
  TabController _tabController;
  @override
  void initState() {
    datepickerfirstProject = FocusNode();
    getHeaderHTTP();
    datepickerlastProject = FocusNode();
    _tabController = TabController(
        length: 2, vsync: _ChooseProjectAvailableState(), initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    super.initState();
    _controllerNamaProject.text = '';
    _controllerTanggalAwalProject.text = '';
    _controllerTanggalAkhirProject.text = '';
    _tanggalawalProject = 'kosong';
    _tanggalakhirProject = 'kosong';
    isLoading = true;
    focus = false;
    listProject = [];
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
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
    return getDataProject();
  }

  Future<List<List>> getDataProject() async {
    setState(() {
      listProject.clear();
      listProject = [];
    });
    print(widget.idproject);
    setState(() {
      isLoading = true;
    });
    try {
      final getDataProject = await http
          .post(url('api/getdata_project'), headers: requestHeaders, body: {
        'filter': '',
      });

      if (getDataProject.statusCode == 200) {
        var getDetailProjectJson = json.decode(getDataProject.body);
        print(getDetailProjectJson);
        var projects = getDetailProjectJson['project'];

        for (var i in projects) {
          DateTime yearStart = DateTime.parse(i['p_timestart']);
          DateTime yearEnd = DateTime.parse(i['p_timeend']);
          Project todo = Project(
            id: i['p_id'],
            title: i['p_name'],
            start: yearStart.year == yearEnd.year
                ? DateFormat("dd MMMM").format(DateTime.parse(i['p_timestart']))
                : DateFormat("dd MMMM yyyy")
                    .format(DateTime.parse(i['p_timestart'])),
            end: DateFormat("dd MMMM yyyy")
                .format(DateTime.parse(i['p_timeend'])),
          );
          listProject.add(todo);
        }

        setState(() {
          isLoading = false;
          isError = false;
        });
      } else if (getDataProject.statusCode == 401) {
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
        print(getDataProject.body);
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

  void _tambahProject() async {
    await progressApiAction.show();
    try {
      Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
      final addadminevent = await http
          .post(url('api/create_project'), headers: requestHeaders, body: {
        'nama_project': _controllerNamaProject.text,
        'time_end':
            _tanggalakhirProject == 'kosong' ? null : _tanggalakhirProject,
        'time_start':
            _tanggalawalProject == 'kosong' ? null : _tanggalawalProject,
      });

      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          String idProject = addpesertaJson['idproject'].toString();
          progressApiAction.hide().then((isHidden) {});
          Fluttertoast.showToast(msg: "Berhasil !");
          setState(() {
            idProjectChoose = idProject;
            namaProjectChoose = _controllerNamaProject.text;
          });
          Navigator.pop(context);
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
      backgroundColor:
           Color.fromRGBO(242, 242, 242, 1),
      appBar: AppBar(
        backgroundColor: primaryAppBarColor,
        title: Text('Pilih Project', style: TextStyle(fontSize: 14)),
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
                          child: Text('Project',
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
                          child: Text('Tambah Project',
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
                                            margin: EdgeInsets.only(top: 0.0,left: 10.0,right: 10.0),
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
                                                          bottom:15.0),
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
                                                        getDataProject();
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
                                            color: Colors.white,
                                            margin: EdgeInsets.only(
                                              top: 0.0,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Container(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: listProject
                                                      .map(
                                                          (Project item) =>
                                                              Card(
                                                                  elevation:
                                                                      0.6,
                                                                  child:
                                                                      ListTile(
                                                                    title: Text(
                                                                        item.title == '' || item.title == null
                                                                            ? 'Nama Project Tidak Diketahui'
                                                                            : item
                                                                                .title,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontWeight:
                                                                                FontWeight.w500)),
                                                                    trailing:
                                                                        GestureDetector(
                                                                      onTap:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          idProjectChoose = item
                                                                              .id
                                                                              .toString();
                                                                          namaProjectChoose =
                                                                              item.title;
                                                                        });
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Container(
                                                                          padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 8.0, bottom: 8.0),
                                                                          decoration: BoxDecoration(border: Border.all(color: primaryAppBarColor), borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                                                          child: Text(
                                                                            'Pilih Project',
                                                                            style:
                                                                                TextStyle(fontSize: 14, color: primaryAppBarColor),
                                                                          )),
                                                                    ),
                                                                    subtitle: Text(
                                                                        '${item.start} - ${item.end}'),
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
                                            margin:
                                                EdgeInsets.only(bottom: 10.0),
                                            child: Text(
                                              'Tambah Project',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
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
                                                    TextAlignVertical.center,
                                                autofocus: focus,
                                                controller:
                                                    _controllerNamaProject,
                                                decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    hintText:
                                                        'Masukkan Nama Project',
                                                    hintStyle: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black,
                                                    )),
                                              )),
                                          Container(
                                            height: 40.0,
                                            alignment: Alignment.center,
                                            margin:
                                                EdgeInsets.only(bottom: 5.0),
                                            child: DateTimeField(
                                              controller:
                                                  _controllerTanggalAwalProject,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.only(
                                                    top: 2,
                                                    bottom: 2,
                                                    left: 10,
                                                    right: 10),
                                                hintText:
                                                    'Tanggal Dimulainya Project ',
                                                hintStyle: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black),
                                              ),
                                              readOnly: true,
                                              format: format,
                                              focusNode: datepickerfirstProject,
                                              onShowPicker: (context,
                                                  currentValue) async {
                                                return await showDatePicker(
                                                    context: context,
                                                    firstDate: DateTime.now(),
                                                    initialDate: DateTime.now(),
                                                    lastDate: DateTime(2100));
                                              },
                                              onChanged: (ini) {
                                                setState(() {
                                                  _controllerTanggalAkhirProject
                                                      .text = '';
                                                  _tanggalakhirProject =
                                                      'kosong';
                                                  _tanggalawalProject =
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
                                            margin:
                                                EdgeInsets.only(bottom: 5.0),
                                            child: DateTimeField(
                                              controller:
                                                  _controllerTanggalAkhirProject,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.only(
                                                    top: 2,
                                                    bottom: 2,
                                                    left: 10,
                                                    right: 10),
                                                hintText:
                                                    'Tanggal Berakhirnya Project',
                                                hintStyle: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black),
                                              ),
                                              readOnly: true,
                                              format: format,
                                              focusNode: datepickerlastProject,
                                              onShowPicker: (context,
                                                  currentValue) async {
                                                return await showDatePicker(
                                                    context: context,
                                                    firstDate:
                                                        _tanggalawalProject ==
                                                                'kosong'
                                                            ? DateTime.now()
                                                            : DateTime.parse(
                                                                _tanggalawalProject),
                                                    initialDate:
                                                        _tanggalawalProject ==
                                                                'kosong'
                                                            ? DateTime.now()
                                                            : DateTime.parse(
                                                                _tanggalawalProject),
                                                    lastDate: DateTime(2100));
                                              },
                                              onChanged: (ini) {
                                                setState(() {
                                                  _tanggalakhirProject =
                                                      ini == null
                                                          ? 'kosong'
                                                          : ini.toString();
                                                });
                                              },
                                            ),
                                          ),
                                          Center(
                                              child: Container(
                                                  margin: EdgeInsets.only(
                                                      top: 10.0, bottom: 15.0),
                                                  width: double.infinity,
                                                  height: 40.0,
                                                  child: RaisedButton(
                                                      onPressed: () async {
                                                        if (_controllerNamaProject
                                                                .text ==
                                                            '') {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'Masukkan Nama Project');
                                                        } else if (_controllerTanggalAwalProject
                                                                .text ==
                                                            '') {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'Tanggal Dimulainya Project Tidak Boleh Kosong');
                                                        } else if (_controllerTanggalAkhirProject
                                                                .text ==
                                                            '') {
                                                          Fluttertoast.showToast(
                                                              msg:
                                                                  'Tanggal Berakhirnya Project Tidak Boleh Kosong');
                                                        } else {
                                                          _tambahProject();
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
                                                          "Tambahkan Project",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .white)))))
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
}
