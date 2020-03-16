import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todolist_app/src/routes/env.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:todolist_app/src/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:todolist_app/src/utils/utils.dart';
import 'package:todolist_app/src/pages/dashboard.dart';

String tokenType, accessToken;
Map<String, String> requestHeaders = Map();

class ManageDeleteTodo extends StatefulWidget {
  ManageDeleteTodo({Key key, this.title, this.idtodo, this.namatodo})
      : super(key: key);
  final String title, namatodo;
  final int idtodo;
  @override
  State<StatefulWidget> createState() {
    return _ManageDeleteTodoState();
  }
}

class _ManageDeleteTodoState extends State<ManageDeleteTodo> {
  ProgressDialog progressApiAction;
  @override
  void initState() {
    super.initState();
    getHeaderHTTP();
  }

  Future<void> getHeaderHTTP() async {
    var storage = new DataStore();

    var tokenTypeStorage = await storage.getDataString('token_type');
    var accessTokenStorage = await storage.getDataString('access_token');

    tokenType = tokenTypeStorage;
    accessToken = accessTokenStorage;

    requestHeaders['Accept'] = 'application/json';
    requestHeaders['Authorization'] = '$tokenType $accessToken';
  }

  void deletetodo() async {
    try {
      progressApiAction.show();
      final deleteProjectUrl = await http.post(url('api/delete_todo'),
          headers: requestHeaders,
          body: {'todolist': widget.idtodo.toString()});

      if (deleteProjectUrl.statusCode == 200) {
        var deleteProjectJson = json.decode(deleteProjectUrl.body);
        if (deleteProjectJson['status'] == 'success') {
          Fluttertoast.showToast(msg: 'Berhasil');
          progressApiAction.hide().then((isHidden) => null);
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Dashboard()),
              (Route<dynamic> route) => false);
        }
      } else {
        Fluttertoast.showToast(msg: 'Gagal, silahkan coba kembali');
        progressApiAction.hide().then((isHidden) => null);
        print(deleteProjectUrl.body);
      }
    } on TimeoutException {
      Fluttertoast.showToast(msg: 'Time Out, Try Again');
      progressApiAction.hide().then((isHidden) => null);
    } catch (e) {
      print(e.toString());
      Fluttertoast.showToast(msg: 'Gagal, silahkan coba kembali');
      progressApiAction.hide().then((isHidden) => null);
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
      backgroundColor: Colors.white,
      appBar: new AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: new Text(
          "Hapus ToDo ${widget.namatodo}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryAppBarColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
                child: Text(
                  'Menghapus ToDo ${widget.namatodo} ?',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Jika anda ingin menghapus ToDo ini, semua data yang berhubungan dengan ToDo ini akan dihapus secara permanen, misalnya : ToDo Activity, Member, dll.',
                  style:
                      TextStyle(color: Colors.black54, fontSize: 14, height: 2),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                      child: Container(
                    margin: EdgeInsets.only(right: 3),
                    child: ButtonTheme(
                      child: FlatButton(
                        color: primaryAppBarColor,
                        onPressed: () async {
                          deletetodo();
                        },
                        splashColor: Colors.blue,
                        child: Text(
                          'Hapus Sekarang',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )),
                  Expanded(
                      child: Container(
                    margin: EdgeInsets.only(left: 3),
                    child: ButtonTheme(
                      child: OutlineButton(
                        borderSide: BorderSide(color: Colors.grey),
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        splashColor: Colors.blue,
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
