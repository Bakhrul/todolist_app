import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:todolist_app/src/pages/todolist/adduserfile.dart';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/models/category.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:shimmer/shimmer.dart';
import 'choose_project.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:flutter/services.dart';

String tokenType, accessToken;
String categoriesID;
String categoriesName;
bool isLoading, isError;
String idProjectChoose;
String namaProjectChoose;
bool isAllday;

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  ProgressDialog progressApiAction;
  final _formKey = GlobalKey<FormState>();
  
  DateTime timeReplacement;
  List<Category> listCategory = [];

  String _dfileName;
  String fileImage;
  bool _loadingPath = false;
  bool _hasValidMime = false;
  FileType _pickingType;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _dateStartController = TextEditingController();
  TextEditingController _dateEndController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
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
    return requestHeaders;
  }

  Future<List<List>> getDataCategory() async {
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
    try {
      final participant =
          await http.get(url('api/category'), headers: requestHeaders);

      if (participant.statusCode == 200) {
        var listParticipantToJson = json.decode(participant.body);
        var participants = listParticipantToJson;
        print(participants);
        for (var i in participants) {
          Category participant = Category(
            id: i['id'],
            name: i['name'].toString(),
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

  Future<void> saveTodo() async {
    await progressApiAction.show();
    try {
      dynamic body = {
        "title": _titleController.text.toString(),
        "planstart": _dateStartController.text.toString(),
        "planend": _dateEndController.text.toString(),
        "desc": _descController.text.toString(),
        "category": categoriesID.toString(),
        'project': idProjectChoose.toString(),
        'allday' : isAllday == false ? '0' : '1',
      };
      final addadminevent = await http.post(url('api/todo/create'),
          headers: requestHeaders, body: body);
      print(addadminevent);
      if (addadminevent.statusCode == 200) {
        var addpesertaJson = json.decode(addadminevent.body);
        if (addpesertaJson['status'] == 'success') {
          Fluttertoast.showToast(msg: "Berhasil !");
          var idTodo = addpesertaJson['data'];
          progressApiAction.hide().then((isHidden) {});
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AddUserFileTodo(idTodo: idTodo)));
          setState(() {});
        }
      } else {
        print(addadminevent.body);
        progressApiAction.hide().then((isHidden) {});
        Fluttertoast.showToast(msg: "Gagal, Silahkan Coba Kembalis");
      }
    } on TimeoutException catch (_) {
      progressApiAction.hide().then((isHidden) {});
      Fluttertoast.showToast(msg: "Timed out, Try again");
    }
  }

  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateStartController.dispose();
    _dateEndController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    getHeaderHTTP();
    isAllday = false;
    namaProjectChoose = null;
    _titleController.text = '';
    _dateStartController.text = '';
    _dateEndController.text = '';
    _descController.text = '';
    categoriesID = null;
    idProjectChoose = null;
    _dfileName = null;
    fileImage = null;
    getDataCategory();
    timeSetToMinute();
    super.initState();
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
      backgroundColor: isError == true ? Colors.white : Colors.white,
      appBar: AppBar(
        backgroundColor: primaryAppBarColor,
        title: Text(
          "Tambahkan To Do",
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ),
      body: Container(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                isLoading == true
                    ? _loadingview()
                    : isError == true
                        ? Container(
                            color: Colors.white,
                            margin: EdgeInsets.only(
                                top: 15.0, left: 10.0, right: 10.0),
                            padding:
                                const EdgeInsets.only(top: 10.0, bottom: 25.0),
                            child: RefreshIndicator(
                              onRefresh: () => getDataCategory(),
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
                                      top: 15.0,
                                      left: 15.0,
                                      right: 15.0,
                                      bottom: 15.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: RaisedButton(
                                      color: Colors.white,
                                      textColor: primaryAppBarColor,
                                      disabledColor: Colors.grey,
                                      disabledTextColor: Colors.black,
                                      padding: EdgeInsets.all(15.0),
                                      onPressed: () async {
                                        getDataCategory();
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
                              ]),
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.only(top: 10.0),
                            color: Colors.white,
                            width: double.infinity,
                            padding: EdgeInsets.only(
                              left: 10.0,
                              right: 10.0,
                              top: 20.0,
                              bottom: 15.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                    alignment: Alignment.center,
                                    height: 45.0,
                                    margin: EdgeInsets.only(
                                        bottom: 10.0, top: 10.0),
                                    child: TextField(
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Nama To Do',
                                          hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black)),
                                      controller: _titleController,
                                    )),
                                    Text("Pelaksanaan Kegiatan"),
                                Row(
                                  children: <Widget>[
                                    Container(
                                      child: Checkbox(
                                        value: isAllday,
                                        // checkColor: Colors.green,
                                        activeColor: Colors.green,
                                        onChanged: (bool value) {
                                          setState(() {
                                          isAllday = value;
                                          _dateStartController.text = '';
                                          _dateEndController.text = '';
                                        });
                                        }, 
                                        
                                      ),
                                    ),
                                    Text("All Day")
                                  ],
                                ),
                                Container(
                                    alignment: Alignment.center,
                                    height: 45.0,
                                    margin: EdgeInsets.only(bottom: 10.0),
                                    child: DateTimeField(
                                      controller: _dateStartController,
                                      format: isAllday != true
                                          ? DateFormat("dd-MM-yyyy HH:mm:ss")
                                          : DateFormat("dd-MM-yyyy "),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            top: 2,
                                            bottom: 2,
                                            left: 10,
                                            right: 10),
                                        border: OutlineInputBorder(),
                                        hintText: 'Tanggal Mulainya To Do',
                                        hintStyle: TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                      onShowPicker:
                                          (context, currentValue) async {
                                        final date = await showDatePicker(
                                            context: context,
                                            firstDate: DateTime(2018),
                                            initialDate: DateTime.now(),
                                            lastDate: DateTime(2100));
                                        if (date != null) {
                                          if (isAllday != true) {
                                            final times = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                      currentValue ??
                                                          timeReplacement),
                                            );
                                            return DateTimeField.combine(
                                                date, times);
                                          } else {
                                            final time = TimeOfDay.fromDateTime(
                                                timeReplacement);
                                            return DateTimeField.combine(
                                                date, time);
                                          }
                                        } else {
                                          return currentValue;
                                        }
                                      },
                                      onChanged: (ini) {
                                        setState(() {
                                          _dateEndController.text = '';
                                        });
                                      },
                                    )),
                                    
                              
                                Container(
                                    alignment: Alignment.center,
                                    height: 45.0,
                                    margin: EdgeInsets.only(bottom: 10.0),
                                    child: DateTimeField(
                                      controller: _dateEndController,
                                      format: isAllday != true
                                          ? DateFormat("dd-MM-yyyy HH:mm:ss")
                                          : DateFormat("dd-MM-yyyy "),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            top: 2,
                                            bottom: 2,
                                            left: 10,
                                            right: 10),
                                        border: OutlineInputBorder(),
                                        hintText: 'Tanggal Berakhirnya To Do',
                                        hintStyle: TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                      onShowPicker:
                                          (context, currentValue) async {
                                            DateFormat inputFormat = DateFormat("dd-MM-yyyy");
                                            DateTime dateTime = inputFormat.parse("${_dateStartController.text}");

                                            print(dateTime);
                                        final date = await showDatePicker(
                                            context: context,
                                            firstDate:
                                                _dateStartController.text == ''
                                                    ? DateTime.now()
                                                    : dateTime,
                                            initialDate:
                                                _dateStartController.text == ''
                                                    ? DateTime.now()
                                                    : dateTime,
                                            lastDate: DateTime(2100));
                                        if (date != null) {
                                          if (isAllday != true) {
                                            final times = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(
                                                      currentValue ??
                                                          timeReplacement),
                                            );
                                            return DateTimeField.combine(
                                                date, times);
                                          } else {
                                            final time = TimeOfDay.fromDateTime(
                                                timeReplacement);
                                            return DateTimeField.combine(
                                                date, time);
                                          }
                                        } else {
                                          return currentValue;
                                        }
                                      },
                                    )) ,
                                    

                                InkWell(
                                  onTap: () async {
                                    showCategory();
                                  },
                                  child: Container(
                                    height: 45.0,
                                    padding: EdgeInsets.only(
                                        left: 10.0, right: 10.0),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.black45),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5.0))),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                            categoriesID == null
                                                ? "Pilih Kategori"
                                                : 'Kategori - $categoriesName',
                                            style: TextStyle(fontSize: 12),
                                            textAlign: TextAlign.left),
                                      ],
                                    ),
                                  ),
                                ),
                                categoriesID == '1'
                                    ? GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChooseProjectAvailable()));
                                          setState(() {
                                            namaProjectChoose =
                                                namaProjectChoose;
                                          });
                                        },
                                        child: Container(
                                          height: 45.0,
                                          margin: EdgeInsets.only(top: 10.0),
                                          padding: EdgeInsets.only(
                                              left: 10.0, right: 10.0),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black45),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5.0))),
                                          child: Row(
                                            // crossAxisAlignment:
                                            //     CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Expanded(
                                                child: Text(
                                                    namaProjectChoose == null
                                                        ? 'Pilih Project'
                                                        : 'Project $namaProjectChoose',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true,
                                                    maxLines: 1,
                                                    textAlign: TextAlign.left),
                                              ),
                                              Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Container(),
                                Container(
                                    margin: EdgeInsets.only(
                                        bottom: 10.0, top: 10.0),
                                    height: 120.0,
                                    child: TextField(
                                      maxLines: 10,
                                      controller: _descController,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Deskripsi',
                                          hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black)),
                                    )),
                                // Container(
                                //     margin: EdgeInsets.only(
                                //         bottom: 10.0, top: 10.0),
                                //     child: FlatButton(
                                //       onPressed: () {
                                //         Navigator.push(
                                //             context,
                                //             MaterialPageRoute(
                                //                 builder: (context) =>
                                //                     AddUserFileTodo()));
                                //       },
                                //       child: Text("Tambah Attachment",
                                //           style: TextStyle(
                                //               fontWeight: FontWeight.bold)),
                                //     )),
                                // Container(
                                //     width: double.infinity,
                                //     margin: EdgeInsets.only(
                                //       bottom: 10.0,
                                //     ),
                                //     child: FlatButton(
                                //       onPressed: () => _openFileExplorer(),
                                //       child: SizedBox(
                                //         width: double.infinity,
                                //         child: Text(
                                //           'Pilih File',
                                //           textAlign: TextAlign.left,
                                //         ),
                                //       ),
                                //     )),
                                // new Builder(
                                //   builder: (BuildContext context) =>
                                //       // _loadingPath
                                //       //     ? Padding(
                                //       //         padding: const EdgeInsets.only(bottom: 10.0),
                                //       //         child: const CircularProgressIndicator())
                                //       //     :
                                //       _dfileName != null
                                //           ? new Container(
                                //               // padding: const EdgeInsets.only(bottom: 10.0),
                                //               // height: MediaQuery.of(context).size.height / 4,
                                //               child: Text(_dfileName != null
                                //                   ? _dfileName
                                //                   : '..'),
                                //             )
                                //           : new Container(),
                                // ),
                                // Center(
                                //     child: Container(
                                //         margin: EdgeInsets.only(top: 10.0),
                                //         width: double.infinity,
                                //         height: 40.0,
                                //         child: RaisedButton(
                                //             onPressed: () async {
                                //               if (_titleController.text == '') {
                                //                 Fluttertoast.showToast(
                                //                     msg:
                                //                         "Nama To Do Tidak Boleh Kosong");
                                //               } else if (categoriesID
                                //                           .toString() ==
                                //                       '' ||
                                //                   categoriesID == null) {
                                //                 Fluttertoast.showToast(
                                //                     msg:
                                //                         "Kategori Tidak Boleh Kosong");
                                //               } else if (_dateStartController
                                //                       .text ==
                                //                   '') {
                                //                 Fluttertoast.showToast(
                                //                     msg:
                                //                         "Tanggal Dimulainya To Do Tidak Boleh Kosong");
                                //               } else if (_dateEndController
                                //                       .text ==
                                //                   '') {
                                //                 Fluttertoast.showToast(
                                //                     msg:
                                //                         "Tanggal Berakhirnya To Do Tidak Boleh Kosong");
                                //               } else if (_descController.text ==
                                //                   '') {
                                //                 Fluttertoast.showToast(
                                //                     msg:
                                //                         "Deskripsi tidak boleh kosong");
                                //               } else if (categoriesID
                                //                       .toString() ==
                                //                   '1') {
                                //                 if (idProjectChoose == null) {
                                //                   Fluttertoast.showToast(
                                //                       msg:
                                //                           "Silahkan Pilih Project Terlebih Dahulu");
                                //                 } else {
                                //                   saveTodo();
                                //                 }
                                //               } else {
                                //                 saveTodo();
                                //               }
                                //             },
                                //             color: primaryAppBarColor,
                                //             textColor: Colors.white,
                                //             disabledColor: Color.fromRGBO(
                                //                 254, 86, 14, 0.7),
                                //             disabledTextColor: Colors.white,
                                //             splashColor: Colors.blueAccent,
                                //             child: Text("Tambahkan To Do",
                                //                 style: TextStyle(
                                //                     fontSize: 12,
                                //                     color: Colors.white)))))
                              ],
                            )),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_titleController.text == '') {
            Fluttertoast.showToast(msg: "Nama To Do Tidak Boleh Kosong");
          } else if (categoriesID.toString() == '' || categoriesID == null) {
            Fluttertoast.showToast(msg: "Kategori Tidak Boleh Kosong");
          } else if (_dateStartController.text == '') {
            Fluttertoast.showToast(
                msg: "Tanggal Dimulainya To Do Tidak Boleh Kosong");
          } else if (_dateEndController.text == '') {
            Fluttertoast.showToast(
                msg: "Tanggal Berakhirnya To Do Tidak Boleh Kosong");
          } else if (_descController.text == '') {
            Fluttertoast.showToast(msg: "Deskripsi tidak boleh kosong");
          } else if (categoriesID.toString() == '1') {
            if (idProjectChoose == null) {
              Fluttertoast.showToast(
                  msg: "Silahkan Pilih Project Terlebih Dahulu");
            } else {
              saveTodo();
            }
          } else {
            saveTodo();
          }
        },
        backgroundColor: primaryAppBarColor,
        child: Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  void showCategory() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (builder) {
          return Container(
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
          );
        });
  }

  Widget _loadingview() {
    return Container(
        color: Colors.white,
        margin: EdgeInsets.only(
          top: 15.0,
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
              children: [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
              ]
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
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
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

  void _openFileExplorer() async {
    if (_pickingType != FileType.CUSTOM || _hasValidMime) {
      setState(() => _loadingPath = true);
      try {
        //  _path = await FilePicker. getFilePath(
        //     type: _pickingType, fileExtension: _extension,);
        File file = await FilePicker.getFile(type: FileType.ANY);
        setState(() {
          _dfileName = file.toString();
          fileImage = base64Encode(file.readAsBytesSync());
          _loadingPath = false;
        });
        // print("Extensi");
        // print(file.toString().split('/').last);

      } on PlatformException catch (e) {
        print("Unsupported operation" + e.toString());
      }
      if (!mounted) return;
      // setState(() {
      //   _loadingPath = false;
      //   _fileName = _path != null
      //       ? _path.split('/').last
      //       : _paths != null ? _paths.keys.toString() : '...';
      // });
    }
  }
}
