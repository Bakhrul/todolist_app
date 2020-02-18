import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:todolist_app/src/routes/env.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'dart:async';
import 'package:todolist_app/src/model/category.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'tambah_category.dart';
import 'dart:io';
import 'dart:convert';

String tokenType, accessToken;
File _image;
Map<String, dynamic> formSerialize;
var datepickerfirst, datepickerlast;
bool isCreate;
String _tanggalawalProject, _tanggalakhirProject;
Map<String, String> requestHeaders = Map();
List<ListKategoriAdd> listKategoriAdd = [];
TextEditingController _namaprojectController = TextEditingController();
TextEditingController _tanggalawalProjectController = TextEditingController();
TextEditingController _tanggalakhirProjectController = TextEditingController();

class ManajemenCreateProject extends StatefulWidget {
  ManajemenCreateProject({Key key, this.title}) : super(key: key);
  final String title;
  @override
  State<StatefulWidget> createState() {
    return _ManajemenCreateProjectState();
  }
}

class _ManajemenCreateProjectState extends State<ManajemenCreateProject>
    with SingleTickerProviderStateMixin {
  ProgressDialog progressApiAction;
  TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tanggalawalProject = 'kosong';
    listKategoriAdd = [];
    listKategoriAdd.clear();
    getHeaderHTTP();
    _tanggalawalProjectController.text = '';
    _tanggalakhirProjectController.text = '';
    _image = null;
    _namaprojectController.text = '';
    _tanggalakhirProject = 'kosong';
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    datepickerfirst = FocusNode();
    datepickerlast = FocusNode();
  }

  void _handleTabIndex() {
    setState(() {});
  }

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
    return requestHeaders;
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
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
    return Scaffold(
      backgroundColor: Colors.white,
      // key: _scaffoldKeyDashboard,
      appBar: AppBar(
        backgroundColor: primaryAppBarColor,
        title: Text('Tambah project', style: TextStyle(fontSize: 14)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            tooltip: 'Simpan Data Project',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('Peringatan!'),
                  content: Text(
                      'Apakah Anda Ingin Memperbarui Data Event Anda Sekarang? '),
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
                        _tambahproject();
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          indicatorColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Informasi'),
            Tab(icon: Icon(Icons.category), text: 'Kategori'),
          ],
        ),
      ), //
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(5.0),
            child: Column(children: <Widget>[
              _image == null
                  ? Container()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(
                              right: 5.0, bottom: 5.0, top: 10.0),
                          width: 30.0,
                          height: 30.0,
                          child: FlatButton(
                            textColor: Colors.white,
                            padding: EdgeInsets.all(0),
                            color: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 14.0,
                            ),
                            onPressed: () async {
                              setState(() {
                                _image = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
              Center(
                child: _image == null
                    ? InkWell(
                        onTap: getImage,
                        child: Container(
                            margin: EdgeInsets.only(
                                left: 5.0, right: 5.0, bottom: 20.0, top: 10.0),
                            width: double.infinity,
                            height: 250.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  width: 1.0,
                                  color: Colors.grey,
                                )),
                            child: Text('Tidak ada gambar yang dipilih.')),
                      )
                    : Container(
                        width: double.infinity,
                        height: 250.0,
                        margin: EdgeInsets.only(
                            left: 5.0, right: 5.0, bottom: 20.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                          width: 1.0,
                          color: Colors.grey,
                        )),
                        child: Image.file(_image),
                      ),
              ),
              Card(
                  child: ListTile(
                leading: Icon(
                  Icons.assignment_ind,
                ),
                title: TextField(
                  controller: _namaprojectController,
                  decoration: InputDecoration(
                      hintText: 'Nama Project',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black)),
                ),
              )),
              Card(
                  child: ListTile(
                leading: Icon(
                  Icons.access_time,
                ),
                title: DateTimeField(
                  controller: _tanggalawalProjectController,
                  readOnly: true,
                  format: DateFormat('dd-MM-yyy'),
                  focusNode: datepickerfirst,
                  initialValue: _tanggalawalProject == 'kosong'
                      ? null
                      : DateTime.parse(_tanggalawalProject),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tanggal Dimulainya Project',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.black),
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
              )),
              Card(
                  child: ListTile(
                leading: Icon(
                  Icons.access_time,
                ),
                title: DateTimeField(
                  controller: _tanggalakhirProjectController,
                  readOnly: true,
                  format: DateFormat('dd-MM-yyy'),
                  focusNode: datepickerlast,
                  initialValue: _tanggalakhirProject == 'kosong'
                      ? null
                      : DateTime.parse(_tanggalakhirProject),
                  decoration: InputDecoration(
                    hintText: 'Tanggal Berakhirnya Project',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 13, color: Colors.black),
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
              )),
            ]),
          ),
          Container(
            child: ListView.builder(
              // scrollDirection: Axis.horizontal,
              itemCount: listKategoriAdd.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                    child: ListTile(
                  leading: ButtonTheme(
                      minWidth: 0.0,
                      child: FlatButton(
                          color: Colors.white,
                          textColor: Colors.red,
                          disabledColor: Colors.white,
                          disabledTextColor: Colors.red[400],
                          padding: EdgeInsets.all(15.0),
                          splashColor: Colors.blueAccent,
                          child: Icon(
                            Icons.close,
                          ),
                          onPressed: () {
                            setState(() {
                              listKategoriAdd.remove(listKategoriAdd[index]);
                            });
                          })),
                  title: Text(listkategori[index].name == null
                      ? 'Unknown Nama'
                      : listkategori[index].name),
                ));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _bottomButtons(),
      // ),
    );
  }

  Widget _bottomButtons() {
    return _tabController.index == 1
        ? DraggableFab(
            child: FloatingActionButton(
                shape: StadiumBorder(),
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ManajemenCreateCategory(
                              listKategoriadd: ListKategoriAdd)));
                },
                backgroundColor: Color.fromRGBO(254, 86, 14, 1),
                child: Icon(
                  Icons.add,
                  size: 20.0,
                )))
        : null;
  }

  void _tambahproject() async {
    Navigator.pop(context);
    await progressApiAction.show();
    Fluttertoast.showToast(msg: "Mohon Tunggu Sebentar");
    formSerialize = Map<String, dynamic>();
    formSerialize['nama_project'] = null;
    formSerialize['tanggal_mulai'] = null;
    formSerialize['tanggal_akhir'] = null;
    formSerialize['gambar'] = null;
    formSerialize['kategori'] = List();

    formSerialize['nama_project'] = _namaprojectController.text;
    if (_image != null) {
      formSerialize['gambar'] = base64Encode(_image.readAsBytesSync());
    }
    formSerialize['tanggal_mulai'] =
        _tanggalawalProject == 'kosong' ? null : _tanggalawalProject;
    formSerialize['tanggal_akhir'] =
        _tanggalakhirProject == 'kosong' ? null : _tanggalakhirProject;

    for (int i = 0; i < listKategoriAdd.length; i++) {
      formSerialize['kategori'] = listKategoriAdd[i].id;
    }

    Map<String, dynamic> requestHeadersX = requestHeaders;

    requestHeadersX['Content-Type'] = "application/x-www-form-urlencoded";
    try {
      final response = await http.post(
        url('api/create_project'),
        headers: requestHeadersX,
        body: {
          'type_platform': 'android',
          'data': jsonEncode(formSerialize),
        },
        encoding: Encoding.getByName("utf-8"),
      );

      if (response.statusCode == 200) {
        dynamic responseJson = jsonDecode(response.body);
        if (responseJson['status'] == 'success') {
          progressApiAction.hide().then((isHidden) {
            print(isHidden);
          });
          Fluttertoast.showToast(msg: "Berhasil !");
          Navigator.pop(context);
        }
      } else {
        print(response.body);
        Fluttertoast.showToast(
            msg: "Gagal Menambahkan Project, Silahkan Coba Kembali");
        progressApiAction.hide().then((isHidden) {
          print(isHidden);
        });
      }
    } on TimeoutException catch (_) {
      Fluttertoast.showToast(msg: "Time Out, Try Again");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Gagal Menambahkan Project, Silahkan Coba Kembali");
      progressApiAction.hide().then((isHidden) {
        print(isHidden);
      });
      Fluttertoast.showToast(msg: e.toString());
      print(e);
    }
  }
}
